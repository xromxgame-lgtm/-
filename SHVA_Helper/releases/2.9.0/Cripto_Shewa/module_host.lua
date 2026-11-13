-- SHVA_Helper module host. Original module authors remain in module metadata.
-- One mimgui context, private Lua globals per module, shared event dispatch.
local Host={}
function Host.new(options)
 local H={items={},commands={},options=options,sampHandlers={}}
 local realGui=options.imgui
 local panelCommands={caselogs='case-opener',bp='battlepass-helper',cchistory='craft-counter',crstats='crypto-collector',crconfig='crypto-collector',cstats='crypto-collector',cconfig='crypto-collector'}
 local function report(item,err)
  if item.error then return end
  item.error=tostring(err);if options.log then options.log(item.id..': '..item.error)end
 end
 local function active(item)return not item.error end
 local function callable(value)
  local kind=type(value)
  if kind=='function'or kind=='cdata'then return true end
  local mt=kind=='table'and getmetatable(value)
  return type(mt)=='table'and mt.__call~=nil
 end
 local function pack(...)return {n=select('#',...),...}end
 local function guarded(item,fn,...)
  local result=pack(pcall(fn,...))
  if not result[1]then report(item,result[2]);return false,result[2]end
  return true,unpack(result,2,result.n)
 end
 local function unwind(item)
  for i=#(item.cleanup or{}),1,-1 do
   local entry=item.cleanup[i];local ok,err=pcall(entry.close)
   if not ok and options.log then options.log(item.id..': UI recovery: '..tostring(err))end
  end
  item.cleanup={};item.depth=0
 end
 local function track(item,kind,close)
  if item.tracking then item.cleanup[#item.cleanup+1]={kind=kind,close=close}end
 end
 local function finish(item,kind,count)
  if not item.tracking then return false end
  count=count or 1
  for _=1,count do
   local found
   for i=#item.cleanup,1,-1 do if item.cleanup[i].kind==kind then found=i;break end end
   if not found then error('Unbalanced UI stack: '..kind,2)end
   local entry=table.remove(item.cleanup,found);entry.close()
  end
  return true
 end
 local function runDraw(item,draw,player)
  item.cleanup={};item.tracking=true
  local ok,err=guarded(item,draw,player)
  if ok and #item.cleanup>0 then ok=false;err='Панель оставила незакрытые элементы интерфейса.';report(item,err)end
  unwind(item);item.tracking=false
  return ok,err
 end
 local function dispatchRaw(item,name,callback,...)
  if name=='onWindowMessage'and options.visible()and H.selected~=item.id then return end
  if (name=='onReceivePacket'or name=='onSendPacket')and item.packetIds then
   local id=select(1,...);if not item.packetIds[id]then return end
  end
  local args=pack(...)
  local stream=(name=='onReceivePacket'or name=='onSendPacket')and args[2]or nil
  local offset
  if stream and type(raknetBitStreamResetReadPointer)=='function'then
   if type(raknetBitStreamGetReadOffset)=='function'then
    local ok,value=pcall(raknetBitStreamGetReadOffset,stream);if ok then offset=value end
   end
   pcall(raknetBitStreamResetReadPointer,stream)
  end
  local result=pack(guarded(item,callback,unpack(args,1,args.n)))
  if stream then
   if offset~=nil and type(raknetBitStreamSetReadOffset)=='function'then pcall(raknetBitStreamSetReadOffset,stream,offset)
   elseif type(raknetBitStreamResetReadPointer)=='function'then pcall(raknetBitStreamResetReadPointer,stream)end
  end
  if result[1]then return unpack(result,2,result.n)end
 end
 local function encodingProxy()
  local original=require 'encoding'
  local private={default=original.default}
  local function scoped(fn,...)
   local old=original.default;original.default=private.default
   local result=pack(pcall(fn,...));original.default=old
   if not result[1]then error(result[2],2)end
   return unpack(result,2,result.n)
  end
  return setmetatable(private,{__index=function(t,key)
   local value=original[key]
   if type(value)=='table'then
    local converter=setmetatable({},{__call=function(_,...)return scoped(value,...)end,__index=function(_,method)
     local fn=value[method]
     if type(fn)=='function'then return function(_,...)return scoped(fn,value,...)end end
     return fn
    end})
    rawset(t,key,converter);return converter
   end
   if type(value)=='function'then return function(...)return scoped(value,...)end end
   return value
  end})
 end
 local function eventProxy(item)
  return setmetatable({},{__newindex=function(_,name,callback)
   if type(callback)~='function'then return end
   if not H.sampHandlers[name]then
    H.sampHandlers[name]={}
    local events=require 'samp.events'
    local existing=events[name]
    events[name]=function(...)
     local result
     if existing then result=existing(...);if result==false then return false end end
     for _,handler in ipairs(H.sampHandlers[name])do
      if active(handler.item)then
       local values=pack(pcall(handler.fn,...))
       if not values[1]then report(handler.item,values[2])
       elseif values[2]==false then return false
       elseif values[2]~=nil then result=values[2]end
      end
     end
     return result
    end
   end
   H.sampHandlers[name][#H.sampHandlers[name]+1]={item=item,fn=callback}
  end,__index=function(_,name)
   for _,handler in ipairs(H.sampHandlers[name]or{})do if handler.item==item then return handler.fn end end
  end})
 end
 local function guiProxy(item)
  local proxy={}
  proxy.OnFrame=function(predicate,draw,...)
   local record={predicate=predicate,draw=draw};item.frames[#item.frames+1]=record
   return realGui.OnFrame(function()
    return active(item)and not options.visible()and (item.id=='case-opener'or item.id=='battlepass-helper')and predicate()
   end,function(player)runDraw(item,draw,player)end,...)
  end
  proxy.OnInitialize=function(fn)return realGui.OnInitialize(function()if active(item)then local ok,err=pcall(fn);if not ok then report(item,err)end end end)end
  proxy.SwitchContext=function()if callable(realGui.SwitchContext)then return realGui.SwitchContext()end end -- Activate the single host context, including calls outside a frame.
  proxy.Begin=function(title,opened,flags)
   if not item.embedding then
    local result=realGui.Begin('SHVA_Helper / '..item.title..'##'..item.id,opened,flags)
    track(item,'Window',function()realGui.End()end);return result
   end
   item.depth=item.depth+1
   local depth=item.depth
   local result=true
   if depth>1 then result=realGui.BeginChild('##host-sub-'..item.id..depth,realGui.ImVec2(0,0),true)end
   track(item,'Window',function()if depth>1 then realGui.EndChild()end;item.depth=item.depth-1 end)
   return result
  end
  proxy.End=function()
   if finish(item,'Window')then return end
   return realGui.End()
  end
  local pairsToTrack={
   {'BeginChild','EndChild',false},{'BeginChildFrame','EndChildFrame',false},
   {'BeginGroup','EndGroup',false},{'BeginTooltip','EndTooltip',false},
   {'BeginCombo','EndCombo',true},{'BeginPopup','EndPopup',true},{'BeginPopupModal','EndPopup',true},
   {'BeginMenu','EndMenu',true},{'BeginMenuBar','EndMenuBar',true},{'BeginMainMenuBar','EndMainMenuBar',true},
   {'BeginTabBar','EndTabBar',true},{'BeginTabItem','EndTabItem',true},{'BeginTable','EndTable',true},
   {'BeginListBox','EndListBox',true},
   {'PushFont','PopFont',false},{'PushID','PopID',false},
   {'PushStyleVar','PopStyleVar',false},{'PushStyleColor','PopStyleColor',false},
   {'PushItemWidth','PopItemWidth',false},{'PushTextWrapPos','PopTextWrapPos',false},
   {'PushAllowKeyboardFocus','PopAllowKeyboardFocus',false},{'PushButtonRepeat','PopButtonRepeat',false},
   {'PushClipRect','PopClipRect',false}}
  for _,entry in ipairs(pairsToTrack)do
   local beginName,endName,conditional=entry[1],entry[2],entry[3]
   if callable(realGui[beginName])and callable(realGui[endName])then
    proxy[beginName]=function(...)
     local result=pack(realGui[beginName](...))
     if not conditional or result[1]then track(item,endName,function()realGui[endName]()end)end
     return unpack(result,1,result.n)
    end
    proxy[endName]=function(count)
     local amount=(endName=='PopStyleVar'or endName=='PopStyleColor')and(count or 1)or 1
     if finish(item,endName,amount)then return end
     if endName=='PopStyleVar'or endName=='PopStyleColor'then return realGui[endName](amount)end
     return realGui[endName]()
    end
   end
  end
  for _,key in ipairs({'SetNextWindowPos','SetNextWindowSize','SetNextWindowCollapsed','SetNextWindowFocus'})do
   local method=key
   proxy[method]=function(...)if not item.embedding then return realGui[method](...)end end
  end
  return setmetatable(proxy,{__index=realGui})
 end
 function H:load(metadata,path)
  if self.items[metadata.id]then return not self.items[metadata.id].error end
  local item={id=metadata.id,title=metadata.title,version=metadata.version,path=path,packetIds=metadata.packetIds,frames={},initializers={},commands={}}
  self.items[item.id]=item
  local env=setmetatable({},{__index=_G});env._G=env
  item.env=env
  env.SHVA_HostSilentStartup=true
  env.SHVA_HostRunInGame=function(fn)
   local function run()
    if active(item)then
     if options.close then options.close()end
     guarded(item,fn)
    end
   end
   if options.dispatch then options.dispatch(run)else run()end
  end
  env.wait=function(ms)
   wait(ms)
   if not active(item)then error('SHVA_Helper module stopped after an earlier error',0)end
  end
  env.addEventHandler=function(name,callback)
   return addEventHandler(name,function(...)
    if active(item)then return dispatchRaw(item,name,callback,...)end
   end)
  end
  env.downloadUrlToFile=function(url,target,callback,...)
   return downloadUrlToFile(url,target,function(...)
    if active(item)and callback then guarded(item,callback,...)end
   end,...)
  end
  env.SHVA_HostOpenUpdates=function()options.navigate('__updates')end
  env.SHVA_HostNavigate=function()options.navigate(item.id)end
  local moduleEncoding=encodingProxy()
  local event=eventProxy(item);local gui=guiProxy(item)
  env.require=function(name)
   if name=='mimgui'then return gui end
   if name=='encoding'then return moduleEncoding end
   if name=='samp.events'then return event end
   return require(name)
  end
  env.script_name=function(value)item.name=value end
  env.script_author=function(value)item.author=value end
  env.script_version=function(value)item.version=value end
  env.script_url=function(value)item.source=value end
  env.thisScript=function()return item end
  env.lua_thread=setmetatable({create=function(fn,...)
   local args=pack(...)
   return lua_thread.create(function()
    if active(item)then guarded(item,fn,unpack(args,1,args.n))end
   end)
  end},{__index=lua_thread})
  env.sampRegisterChatCommand=function(command,callback)
   if self.commands[command]then error('Duplicate hosted command: '..command)end
   self.commands[command]={item=item,fn=callback};item.commands[command]=callback
   if type(sampIsChatCommandDefined)=='function'and sampIsChatCommandDefined(command)then
    report(item,'Команда /'..command..' уже занята другим скриптом. Убери дубликат модуля и перезапусти игру.');return
   end
   sampRegisterChatCommand(command,function(args)
    if not active(item)then return end
    local ok=guarded(item,callback,args)
    if ok and panelCommands[command]then options.navigate(item.id)end
   end)
  end
  local chunk,err=loadfile(path)
  if not chunk then report(item,err);return false end
  setfenv(chunk,env)
  local ok,value=pcall(chunk)
  if not ok then report(item,value);return false end
  for name,callback in pairs(env)do
   if name:match('^on[A-Z]')and type(callback)=='function'then
    local handler,eventName=callback,name
    addEventHandler(eventName,function(...)
     if active(item)then
      return dispatchRaw(item,eventName,handler,...)
     end
    end)
   end
  end
  return true
 end
 function H:start(id)
  local item=self.items[id]
  if not item or item.error or item.started then return false end
  if script and script.find and item.name and script.find(item.name)then report(item,'Найден отдельный экземпляр модуля. Отключи его перед запуском SHVA_Helper.');return false end
  item.started=true
  item.thread=lua_thread.create(function()
   -- LuaJIT supports yieldable protected calls; failures disable this module only.
   if item.env.main then local ok,err=xpcall(item.env.main,debug.traceback);if not ok then report(item,err)end end
  end)
  return true
 end
 function H:call(id,command)
  local item=self.items[id];local key=command:gsub('^/','')
  if not item or item.error then return false,'Модуль не готов.'end
  local fn=item.commands[key]
  if not fn then return false,'Модуль ещё не зарегистрировал действие.'end
  return guarded(item,fn,'')
 end
 function H:prepare(id)
  local item=self.items[id]
  if self.selected==id then return end
  local previous=self.selected and self.items[self.selected]
  if previous and not previous.error and previous.env.SHVA_HostClosePanel then guarded(previous,previous.env.SHVA_HostClosePanel)end
  self.selected=id
  if item and item.started and not item.error and item.env.SHVA_HostPrepare then guarded(item,item.env.SHVA_HostPrepare)end
 end
 function H:hide()
  self.selected=nil
  for _,item in pairs(self.items)do
   if not item.error and item.env.SHVA_HostClosePanel then guarded(item,item.env.SHVA_HostClosePanel)end
  end
 end
 function H:draw(id)
  local item=self.items[id]
  if not item or item.error or not item.started then return false end
  if #item.frames==0 then return false end
  item.embedding=true;item.depth=0
  realGui.PushID('SHVA/'..id)
  realGui.PushStyleVar(realGui.StyleVar.WindowPadding,realGui.ImVec2(12,12))
  realGui.BeginChild('##embedded-'..id,realGui.ImVec2(0,0),false)
  local ok,err=true,nil
  for _,frame in ipairs(item.frames)do
   ok,err=runDraw(item,frame.draw,{HideCursor=false,LockPlayer=true})
   if not ok then break end
  end
  realGui.EndChild();realGui.PopStyleVar();realGui.PopID()
  item.embedding=false
  return ok,err
 end
 return H
end
return Host
