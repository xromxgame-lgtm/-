script_name('SHEVA_Helper')
script_author('SHEVA_Helper; modules by ArzHub')
script_version('2.9.1-embedded-beta')
require 'lib.moonloader'
local moonloader = require 'moonloader'
local guiAvailable,imgui=pcall(require,'mimgui')
if not guiAvailable then
    function main()
        repeat wait(100)until isSampAvailable()
        sampAddChatMessage('{BB7AFF}[SHEVA_Helper] {FFFFFF}mimgui is missing or broken. Install compatible MoonLoader libraries; see moonloader.log.',-1)
        print('SHEVA_Helper: '..tostring(imgui))
    end
    return
end
local ffi = require 'ffi'
local encoding = require 'encoding'
encoding.default = 'UTF-8'
local cp = encoding.CP1251
local root = getWorkingDirectory() .. '/config/Cripto_Shewa'
local moduleRoot = getWorkingDirectory() .. '/Cripto_Shewa/modules/'
local cfg = {name = 'SHEVA_Helper', key = 72, ctrl = true, shift = true, alt = false, server = 32, mode = 'sell', enabled = {}, animation = true, artwork = true, palette = 'violet', skinVersion = 2}
local modules = {
    {id='inventory-plus', name='Inventory Plus', title='Инвентарь', version='2.8.0', desc='Названия и поиск предметов в лавках, шкафах, складах и багажнике. Сортировка, «Забрать всё», MAX и подсчёт стоимости.', help='Открой инвентарь, лавку или хранилище. Улучшения появляются в исходном окне игры автоматически. «Забрать всё» по описанию автора не применяется к лавкам.', actions={{'Обновить справочник', '/ipreload'}}},
    {id='case-opener',name='Case Opener',title='Кейсы',version='2.3.0',desc='Панель открытия кейсов, история дропа и правила автоматического режима.',help='Открой кейс — панель появится в его интерфейсе. Автоматический режим и правила включаются в панели модуля.',actions={{'История и правила','/caselogs'}}},
    {id='battlepass-helper',name='BattlePass Helper',title='Боевой пропуск',version='1.5.0',desc='Задания боевого пропуска, прогресс, закрепление, скрытие и таймер сброса.',help='Настройки и задания открываются кнопкой ниже. Модуль может использовать собственную F9 — переназначь её в его настройках при конфликте.',actions={{'Задания и настройки','/bp'}}},
    {id='crypto-collector',name='Crypto Collector',title='Криптовалюта',version='2.7.1',desc='Сбор криптовалюты из домов, история, состояния карт и список исключений.',help='Для сбора нужна Флешка майнера. Сбор запускается только твоим нажатием, не при входе в игру.',actions={{'История и настройки','/crstats'},{'Настройки сбора','/crconfig'},{'Начать сбор','/crypto'}}},
    {id='dialog-plus',name='Dialog Plus',title='Диалоги',version='1.3.1',desc='Выбор пунктов цифрами, единая нумерация и MAX в поддерживаемых окнах количества.',help='Работает автоматически в поддерживаемых диалогах. Повторное нажатие цифры может подтвердить выбор — учитывай это при покупке.',actions={}},
    {id='craft-counter',name='Craft Counter',title='Крафт',version='1.5.0',desc='Прогресс крафта, удачные и неудачные попытки, расходы, время и история.',help='Счётчик начинает работать после запуска крафта в игре. История открывается кнопкой ниже.',actions={{'История крафтов','/cchistory'}}},
    {id='auto-spawn',name='Auto Spawn',title='Спавн',version='1.1.0',desc='Сохранённое место спавна с автоматическим выбором после отсчёта.',help='Работает с новым интерфейсом авторизации. Отметь нужное место звёздочкой. Не запускай одновременно другие скрипты автоспавна.',actions={}}
}
-- These seven bundled adapters only parse the client CEF packet 220.
for _,m in ipairs(modules)do m.packetIds={[220]=true}end
local servers={'Vice-City','Phoenix','Tucson','Scottdale','Chandler','Brainburg','Saint-Rose','Mesa','Red-Rock','Yuma','Surprise','Prescott','Glendale','Kingman','Winslow','Payson','Gilbert','Show-Low','Casa-Grande','Page','Sun-City','Queen-Creek','Sedona','Holiday','Wednesday','Yava','Faraway','Bumble-Bee','Christmas','Mirage','Love','Drake','Space','Home'}
local defaultSet='https://arzset.fun/?v=3&b=.yI7IPUfQgiJDQAAAAAiOgAAFyUIiQ0AAAAAIhMAAB4tInENAAAAAB6sAAAAAAiJDQAAAAAiMh.zAAAIiQ0AAAAAH-cf2R4qCIkNAAAAAB6mKL4AABz8DAAAAAAc7iMZAAAc-wAAAAAAACeKJ1IAB..-ACekBRT..gAnkgPp..4AJ5UD6QF.'
cfg.setUrl=defaultSet
local opened=imgui.new.bool(false)
local query=imgui.new.char[256]()
local serverFilter=imgui.new.char[96]()
local monitor={rows={},received=0,sourceAge='',error='',busy=false,lastAttempt=0,seq=0,byQueue=false}
local tab=0
local initialized=false
local artwork=nil
local headingFont=nil
local titleFont=nil
local rootIconRanges=nil
local themeDirty=true
local artPath=getWorkingDirectory()..'/Cripto_Shewa/assets/space_city.png'
local binding=false
local deferred={}
local feedback=''
local accent=imgui.ImVec4(1.0,0.74,0.28,1)
local quiet=imgui.ImVec4(0.64,0.68,0.75,1)
local function say(s) sampAddChatMessage('{BB7AFF}[SHEVA_Helper] {FFFFFF}'..cp(s),0xFFFFFF) end
local function log(s)
    local old=io.open(root..'/unified.log','rb')
    if old then local size=old:seek('end');old:close();if size and size>1048576 then os.remove(root..'/unified.log.old');os.rename(root..'/unified.log',root..'/unified.log.old')end end
    local f=io.open(root..'/unified.log','ab')
    if f then f:write(os.date('%Y-%m-%d %H:%M:%S '),s,'\n');f:close() end
end
local function validSet(url) return type(url)=='string' and #url<=4096 and url:match('^https://arzset%.fun/[%w%?&=%.%_%-%%#~]*$')~=nil end
local function readJsonFile(path,limit)
    local function read(candidate)
        local f=io.open(candidate,'rb');if not f then return nil end
        local raw=f:read((limit or 524288)+1);f:close()
        if #raw>(limit or 524288)then return nil end
        local ok,data=pcall(decodeJson,raw)
        if ok and type(data)=='table'then return data,raw end
    end
    local value=read(path);if value then return value,false end
    value=read(path..'.bak');if value then return value,true end
    return nil,false
end
local function writeJsonFile(path,value)
    local ok,data=pcall(encodeJson,value)
    if not ok then return false,'Не удалось подготовить данные для сохранения.'end
    local function write(candidate,bytes)
        local f=io.open(candidate,'wb');if not f then return false end
        local result=f:write(bytes);local closed=f:close();return result~=nil and closed~=nil
    end
    if #data>1048576 then return false,'Файл настроек слишком большой.'end
    if not write(path..'.tmp',data)then return false,'Нет доступа к файлу настроек.'end
    local oldFile=io.open(path,'rb');local existed=oldFile~=nil
    if oldFile then
        local old=oldFile:read(1048577);oldFile:close()
        if #old>1048576 then os.remove(path..'.tmp');return false,'Прежний файл слишком большой; он сохранён без изменений.'end
        local valid,decoded=pcall(decodeJson,old)
        if valid and type(decoded)=='table'then
            if not write(path..'.bak',old)then os.remove(path..'.tmp');return false,'Не удалось сохранить резервную копию настроек.'end
        elseif not write(path..'.corrupt',old)then os.remove(path..'.tmp');return false,'Не удалось сохранить повреждённый файл отдельно.'end
        os.remove(path..'.previous')
        if not os.rename(path,path..'.previous')then os.remove(path..'.tmp');return false,'Файл занят. Изменения не сохранены.'end
    end
    if not os.rename(path..'.tmp',path)then
        local restored=not existed or os.rename(path..'.previous',path)
        os.remove(path..'.tmp')
        return false,restored and 'Сохранение отменено; прежний файл восстановлен.'or'Ошибка восстановления. Используй резервную копию .bak.'
    end
    os.remove(path..'.previous');return true
end
local settingsDirty=false
local function save()
    settingsDirty=true
    local ok,err=writeJsonFile(root..'/unified_settings.json',cfg)
    if not ok then feedback=err;log(err)else settingsDirty=false end
    return ok
end
local function load()
    local d,recovered=readJsonFile(root..'/unified_settings.json')
    if not d then return end
    if recovered then feedback='Настройки восстановлены из резервной копии.';log(feedback)end
    cfg.name='SHEVA_Helper'
    if type(d.key)=='number' and d.key>=32 and d.key<=254 and not(d.key>=112 and d.key<=123) then cfg.key=math.floor(d.key) end
    for _,k in ipairs({'ctrl','shift','alt'}) do if type(d[k])=='boolean' then cfg[k]=d[k] end end
    if not(cfg.ctrl or cfg.shift or cfg.alt)then cfg.key=72;cfg.ctrl=true;cfg.shift=true;cfg.alt=false end
    if type(d.server)=='number' and d.server>=0 and d.server<#servers and d.server==math.floor(d.server) then cfg.server=d.server end
    if d.mode=='sell' or d.mode=='buy' or d.mode=='all' then cfg.mode=d.mode end
    if validSet(d.setUrl) then cfg.setUrl=d.setUrl end
    if type(d.animation)=='boolean'then cfg.animation=d.animation end
    if type(d.artwork)=='boolean'then cfg.artwork=d.artwork end
    if d.skinVersion==2 and(d.palette=='amber'or d.palette=='violet'or d.palette=='teal')then cfg.palette=d.palette end
    if type(d.enabled)=='table' then for _,m in ipairs(modules) do if type(d.enabled[m.id])=='boolean' then cfg.enabled[m.id]=d.enabled[m.id] end end end
end
local host
local function navigateModule(id)
    if id=='__updates'then tab=10 else
        for i,m in ipairs(modules)do if m.id==id then tab=i;break end end
    end
    opened[0]=true
end
local function findModule(m)
    local item=host and host.items[m.id]
    if item and item.started and not item.error then return item end
end
local function startModule(m)
    local item=host and host.items[m.id]
    if not item then m.error='Нужен перезапуск игры для загрузки модуля.';return false end
    if item.error then m.error=item.error;return false end
    if not item.started and not host:start(m.id)then m.error=item.error or 'Не удалось запустить модуль.';return false end
    m.error=nil;return true
end
local function defer(f) deferred[#deferred+1]=f end
local function runAction(m,command)
    if not findModule(m)then feedback='Модуль не готов. Проверь журнал.';return end
    local ok,err=host:call(m.id,command)
    if not ok then feedback=err elseif command=='/crypto'then opened[0]=false else navigateModule(m.id)end
end
-- Load private module environments before mimgui initializes its shared font atlas.
load()
local ok,factory=pcall(dofile,getWorkingDirectory()..'/Cripto_Shewa/module_host.lua')
if ok then
    host=factory.new({imgui=imgui,visible=function()return opened[0]end,navigate=navigateModule,log=log,close=function()opened[0]=false end,dispatch=defer})
    for _,m in ipairs(modules)do
        if cfg.enabled[m.id]~=false then
            local loaded,err=pcall(function()return host:load(m,moduleRoot..m.id..'.lua')end)
            if not loaded or not err then m.error=tostring(not loaded and err or(host.items[m.id]and host.items[m.id].error)or'Ошибка загрузки')end
        end
    end
else log('Module host unavailable: '..tostring(factory))end
local function marketUrl(text)
    local escaped=text:gsub('[^%w%-_%.~]',function(c)return string.format('%%%02X',c:byte())end)
    return 'https://online.arz-mcr.ru/?q='..escaped..'&server='..cfg.server..'&mode='..cfg.mode
end

local function stripHTML(text)
    return (text:gsub('<[^>]*>',' '):gsub('&nbsp;',' '):gsub('&#160;',' '):gsub('\194\160',' '):gsub('&amp;','&'):gsub('%s+',' '):gsub('^%s+',''):gsub('%s+$',''))
end
local function numberText(text)
    if not text then return nil end
    text=stripHTML(text)
    if not text:match('^[%d%s]+$') then return nil end
    local n=tonumber((text:gsub('%s','')))
    if n and n>=0 and n<=1000000 and n==math.floor(n) then return n end
end
local function parseServers(html)
    if type(html)~='string' or #html>2*1024*1024 then return nil,'Неверный размер страницы.' end
    local rows,seen={},{}
    for article in html:gmatch('<article[%s>][^>]*>(.-)</article>')do
        local name=article:match('<h3[^>]*>(.-)</h3>')
        local id=tonumber(article:match('/images/servers/arizona%-(%d+)%.webp'))
        local mobile=tonumber(article:match('/images/servers/arizonaMobile%-(%d+)%.webp'))
        if article:find('/images/servers/vc%-1%.webp')then id=0 elseif mobile then id=100+mobile end
        local stats=article:match('<div[^>]*class="[^"]*items%-baseline[^"]*"[^>]*>(.-)</div>')
        local online,capacity,queue=nil,nil,0
        if stats then
            for span in stats:gmatch('<span[^>]*>(.-)</span>')do
                local plain=stripHTML(span)
                if plain:find('в очереди',1,true)then queue=numberText(plain:match('^(.-)%s+в очереди'))
                elseif plain:match('^/')then capacity=numberText(plain:gsub('^/%s*',''))
                elseif not online then online=numberText(plain)end
            end
        end
        if name and id and online and capacity and queue and capacity>0 and not seen[id]then
            name=stripHTML(name)
            if #name>0 and #name<100 then
                rows[#rows+1]={id=id,name=name,online=online,capacity=capacity,queue=queue};seen[id]=true
            end
        end
    end
    if #rows<10 then return nil,'Сайт не отдал список серверов: возможна блокировка или изменение страницы.' end
    table.sort(rows,function(a,b)return a.id<b.id end)
    local sourceAge='не указано'
    for paragraph in html:gmatch('<p[^>]*>(.-)</p>')do
        local plain=stripHTML(paragraph)
        if plain:find('серверов',1,true)and plain:find('обновлено',1,true)then sourceAge=plain:match('обновлено%s+(.+)$')or sourceAge;break end
    end
    return rows,sourceAge
end
local function saveServerCache()
    local ok,err=writeJsonFile(root..'/servers_cache.json',{rows=monitor.rows,received=monitor.received,sourceAge=monitor.sourceAge})
    if not ok then log(err)end
end
local function loadServerCache()
    local value=readJsonFile(root..'/servers_cache.json')
    if not value or type(value.rows)~='table'then return end
    local rows={}
    for _,r in ipairs(value.rows)do
        if type(r)=='table'and type(r.name)=='string'and type(r.id)=='number'
            and type(r.online)=='number'and type(r.capacity)=='number'and type(r.queue)=='number'
            and r.online>=0 and r.capacity>0 and r.queue>=0 then rows[#rows+1]=r end
    end
    monitor.rows=rows
    if type(value.received)=='number'then monitor.received=value.received end
    if type(value.sourceAge)=='string'then monitor.sourceAge=value.sourceAge end
end
local function refreshServers()
    if monitor.busy then return false end
    if os.time()-monitor.lastAttempt<60 then return false end
    if type(downloadUrlToFile)~='function'then monitor.error='Загрузка недоступна в этой сборке MoonLoader.';return false end
    monitor.lastAttempt=os.time();monitor.deadline=os.time()+25;monitor.busy=true;monitor.error='';monitor.seq=monitor.seq+1
    local seq=monitor.seq
    local path=root..'/servers_request_'..seq..'.html'
    monitor.path=path
    local ok,err=pcall(downloadUrlToFile,'https://arzhub.top/servers',path,function(_,status)
        if status~=moonloader.download_status.STATUSEX_ENDDOWNLOAD then return end
        if seq~=monitor.seq or not monitor.busy then os.remove(path);return end
        monitor.completed=true
    end)
    if not ok then monitor.busy=false;monitor.error='Не удалось начать загрузку: '..tostring(err);log(monitor.error);return false end
    return true
end
local function pollServers()
    if monitor.busy and monitor.completed then
        monitor.completed=false;monitor.busy=false
        local f=io.open(monitor.path,'rb')
        if not f then monitor.error='Данные не получены. Повтори обновление позже.';return end
        local html=f:read(2*1024*1024+1);f:close();os.remove(monitor.path)
        local rows,detail=parseServers(html)
        if rows then monitor.rows=rows;monitor.received=os.time();monitor.sourceAge=detail;monitor.error='';saveServerCache()
        else monitor.error=detail;log('Очереди: '..detail)end
    elseif monitor.busy and os.time()>monitor.deadline then
        monitor.busy=false;monitor.completed=false;monitor.error='Сайт не ответил за 25 секунд. Сохранённые данные не обновлены.';log(monitor.error)
    end
    if opened[0]and tab==11 and not monitor.busy and os.time()-monitor.lastAttempt>=60 then refreshServers()end
end
local function keyName()
    local key=cfg.key>=65 and cfg.key<=90 and string.char(cfg.key) or ('VK '..cfg.key)
    return (cfg.ctrl and 'Ctrl+' or '')..(cfg.shift and 'Shift+' or '')..(cfg.alt and 'Alt+' or '')..key
end

local function updateAccent()
    if cfg.palette=='violet'then accent=imgui.ImVec4(0.73,0.48,1.0,1)
    elseif cfg.palette=='teal'then accent=imgui.ImVec4(0.28,0.84,0.76,1)
    else accent=imgui.ImVec4(1.0,0.75,0.34,1)end
end
local function theme()
    updateAccent()
    local st=imgui.GetStyle()
    st.WindowRounding=14;st.ChildRounding=10;st.FrameRounding=7;st.GrabRounding=7;st.ScrollbarRounding=9
    st.WindowBorderSize=1;st.ChildBorderSize=1;st.FrameBorderSize=0
    st.WindowPadding=imgui.ImVec2(16,16);st.ItemSpacing=imgui.ImVec2(12,10);st.FramePadding=imgui.ImVec2(12,8)
    st.ScrollbarSize=8
    local c=st.Colors
    c[imgui.Col.WindowBg]=imgui.ImVec4(0.025,0.027,0.065,0.99)
    c[imgui.Col.ChildBg]=imgui.ImVec4(0.045,0.050,0.105,0.86)
    c[imgui.Col.Border]=imgui.ImVec4(0.29,0.20,0.48,0.58)
    c[imgui.Col.Text]=imgui.ImVec4(0.94,0.95,0.98,1)
    c[imgui.Col.TextDisabled]=imgui.ImVec4(0.52,0.56,0.65,1)
    c[imgui.Col.Button]=imgui.ImVec4(0.13,0.15,0.21,1)
    c[imgui.Col.ButtonHovered]=imgui.ImVec4(accent.x*0.29,accent.y*0.29,accent.z*0.29,1)
    c[imgui.Col.ButtonActive]=imgui.ImVec4(accent.x*0.40,accent.y*0.40,accent.z*0.40,1)
    c[imgui.Col.FrameBg]=imgui.ImVec4(0.09,0.105,0.15,1)
    c[imgui.Col.FrameBgHovered]=imgui.ImVec4(0.13,0.15,0.21,1)
    c[imgui.Col.CheckMark]=accent
    c[imgui.Col.Header]=imgui.ImVec4(accent.x*0.22,accent.y*0.22,accent.z*0.22,1)
    c[imgui.Col.HeaderHovered]=imgui.ImVec4(accent.x*0.29,accent.y*0.29,accent.z*0.29,1)
    c[imgui.Col.ScrollbarBg]=imgui.ImVec4(0.035,0.04,0.06,0.7)
    c[imgui.Col.ScrollbarGrab]=imgui.ImVec4(0.22,0.24,0.32,1)
end
local function clockSeconds()
    return type(getGameTimer)=='function'and getGameTimer()/1000 or os.clock()
end
local function pulseAlpha()
    if not cfg.animation then return 1 end
    return 0.76+0.24*(0.5+0.5*math.sin(clockSeconds()*1.8))
end
local function drawHero(compact)
    local pos=imgui.GetCursorScreenPos()
    local width=math.max(100,imgui.GetContentRegionAvail().x)
    local height=compact and 112 or 190
    local draw=imgui.GetWindowDrawList()
    local edge=imgui.ImVec2(pos.x+width,pos.y+height)
    draw:AddRectFilled(pos,edge,imgui.GetColorU32Vec4(imgui.ImVec4(0.08,0.07,0.14,1)),10)
    if cfg.artwork and artwork then
        local crop=math.min(1,(1664/936)/(width/height))
        local v0=math.max(0,math.min(1-crop,0.28-crop/2))
        draw:AddImage(artwork,pos,edge,imgui.ImVec2(0,v0),imgui.ImVec2(1,v0+crop),imgui.GetColorU32Vec4(imgui.ImVec4(1,1,1,0.88)))
        draw:AddRectFilledMultiColor(pos,edge,
            imgui.GetColorU32Vec4(imgui.ImVec4(0.025,0.032,0.065,0.88)),
            imgui.GetColorU32Vec4(imgui.ImVec4(0.025,0.032,0.065,0.12)),
            imgui.GetColorU32Vec4(imgui.ImVec4(0.025,0.032,0.065,0.32)),
            imgui.GetColorU32Vec4(imgui.ImVec4(0.025,0.032,0.065,0.91)))
    end
    if cfg.animation then
        for i=1,9 do
            local x=pos.x+width*(0.48+0.49*((i*0.127+clockSeconds()*0.008)%1))
            local y=pos.y+height*(0.15+0.68*((i*0.193)%1))
            draw:AddCircleFilled(imgui.ImVec2(x,y),1+(i%2)*0.5,imgui.GetColorU32Vec4(imgui.ImVec4(0.27,0.86,1,0.24*pulseAlpha())))
        end
    end
    draw:AddRectFilled(imgui.ImVec2(pos.x,pos.y+height-2),edge,imgui.GetColorU32Vec4(imgui.ImVec4(accent.x,accent.y,accent.z,0.75*pulseAlpha())))
    local eyebrow='ARIZONA / SPACE EDITION'
    local eyebrowSize=imgui.CalcTextSize(eyebrow)
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x+math.max(12,(width-eyebrowSize.x)/2),pos.y+(compact and 10 or 18)))
    imgui.TextColored(accent,eyebrow)
    local chosenFont=titleFont or headingFont
    if chosenFont then imgui.PushFont(chosenFont)end
    local nameSize=imgui.CalcTextSize(cfg.name)
    if nameSize.x>width-32 and chosenFont and headingFont and chosenFont~=headingFont then
        imgui.PopFont();chosenFont=headingFont;imgui.PushFont(chosenFont);nameSize=imgui.CalcTextSize(cfg.name)
    end
    local textPos=imgui.ImVec2(pos.x+math.max(14,(width-nameSize.x)/2),pos.y+(height-nameSize.y)/2)
    draw:AddRectFilled(imgui.ImVec2(textPos.x-16,textPos.y-7),imgui.ImVec2(textPos.x+nameSize.x+16,textPos.y+nameSize.y+7),imgui.GetColorU32Vec4(imgui.ImVec4(0.025,0.015,0.07,0.25)),8)
    for _,offset in ipairs({{-3,0},{3,0},{0,-3},{0,3}})do
        draw:AddText(imgui.ImVec2(textPos.x+offset[1],textPos.y+offset[2]),imgui.GetColorU32Vec4(imgui.ImVec4(0.72,0.30,1,0.33*pulseAlpha())),cfg.name)
    end
    for _,offset in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do
        draw:AddText(imgui.ImVec2(textPos.x+offset[1],textPos.y+offset[2]),imgui.GetColorU32Vec4(imgui.ImVec4(0.20,0.88,1,0.25*pulseAlpha())),cfg.name)
    end
    imgui.SetCursorScreenPos(textPos)
    imgui.TextColored(imgui.ImVec4(0.96,0.93,1,1),cfg.name)
    if chosenFont then imgui.PopFont()end
    if not compact then
        local tagline='Твой сервер. Твоя орбита. Твои инструменты.'
        local taglineSize=imgui.CalcTextSize(tagline)
        imgui.SetCursorScreenPos(imgui.ImVec2(pos.x+math.max(12,(width-taglineSize.x)/2),textPos.y+nameSize.y+18))
        imgui.TextColored(imgui.ImVec4(0.76,0.79,0.88,1),tagline)
    end
    imgui.SetCursorScreenPos(pos);imgui.Dummy(imgui.ImVec2(width,height+6))
end
local function badge(text,good)
    local col=good and imgui.ImVec4(0.40,0.87,0.68,1)or quiet
    local pos=imgui.GetCursorScreenPos();local size=imgui.CalcTextSize(text)
    imgui.GetWindowDrawList():AddRectFilled(pos,imgui.ImVec2(pos.x+size.x+20,pos.y+size.y+10),imgui.GetColorU32Vec4(imgui.ImVec4(col.x,col.y,col.z,0.09)),5)
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x+10,pos.y+5));imgui.TextColored(col,text)
    imgui.SetCursorScreenPos(pos);imgui.Dummy(imgui.ImVec2(size.x+20,size.y+12))
end
imgui.OnInitialize(function()
    local io=imgui.GetIO()
    local font=(os.getenv('WINDIR')or'C:/Windows')..'/Fonts/tahoma.ttf'
    if doesFileExist(font)then
        local ranges=io.Fonts:GetGlyphRangesCyrillic()
        local bodyFont=io.Fonts:AddFontFromFileTTF(font,16,nil,ranges)
        if bodyFont then io.FontDefault=bodyFont end
        -- Merge icons into the same deterministic default font used by all panels.
        local iconsAvailable,icons=pcall(require,'fAwesome6')
        if bodyFont and iconsAvailable then
            local ok,err=pcall(function()
                local config=imgui.ImFontConfig();config.MergeMode=true
                rootIconRanges=imgui.new.ImWchar[3](icons.min_range,icons.max_range,0)
                io.Fonts:AddFontFromMemoryCompressedBase85TTF(icons.get_font_data_base85('solid'),14,config,rootIconRanges)
            end)
            if not ok then log('Значки недоступны: '..tostring(err))end
        end
        headingFont=io.Fonts:AddFontFromFileTTF(font,22,nil,ranges)
        titleFont=io.Fonts:AddFontFromFileTTF(font,38,nil,ranges)
    end
    if imgui.CreateTextureFromFile~=nil and doesFileExist(artPath)then
        local ok,texture=pcall(imgui.CreateTextureFromFile,artPath)
        if ok and texture then artwork=texture else log('Фон недоступен; используется однотонная тема.')end
    end
    theme();initialized=true
end)
local function section(title,description)
    if headingFont then imgui.PushFont(headingFont)end
    imgui.Text(title)
    if headingFont then imgui.PopFont()end
    imgui.Spacing();imgui.TextColored(quiet,'SHEVA / '..title:upper());imgui.Separator()
    imgui.TextWrapped(description);imgui.Spacing()
end
local function drawModule(m)
    local item=host and host.items[m.id];if item and item.error then m.error=item.error end
    local hasPanel=item and item.frames and #item.frames>0
    if hasPanel then
        imgui.TextColored(accent,'SHEVA_Helper / '..m.title);imgui.SameLine();imgui.TextDisabled('v'..m.version)
    else section(m.title,m.desc)end
    if m.id=='inventory-plus'then
        local features={{'Поиск предметов','Лавки, шкафы, склады, багажник'},{'Сортировка','Предметы в алфавитном порядке'},{'Забрать всё','Поддерживаемые хранилища, кроме лавок'},{'MAX и «Итого»','Количество и стоимость в окнах покупки'}}
        local width=imgui.GetContentRegionAvail().x
        local columns=width>=500 and 2 or 1
        for i,item in ipairs(features)do
            imgui.BeginChild('##feature'..i,imgui.ImVec2((width-(columns-1)*12)/columns,88),true,imgui.WindowFlags.NoScrollbar)
            imgui.TextColored(accent,item[1]);imgui.TextWrapped(item[2]);imgui.EndChild()
            if i%columns~=0 and i<#features then imgui.SameLine()end
        end
        imgui.Spacing()
    end
    local live=findModule(m)~=nil
    imgui.TextColored(live and imgui.ImVec4(0.40,0.87,0.65,1) or quiet,live and 'Модуль загружен' or 'Модуль не загружен')
    if imgui.CollapsingHeader('Описание и параметры##'..m.id)then
    imgui.TextWrapped(m.desc)
    local enabled=imgui.new.bool(cfg.enabled[m.id]~=false)
    if imgui.Checkbox('Включать при запуске##'..m.id,enabled) then
        cfg.enabled[m.id]=enabled[0];save()
        if enabled[0] and not live then defer(function()startModule(m)end)
        elseif not enabled[0] and live then feedback='Отключится после полного перезапуска игры. Игровые CEF-изменения нельзя надёжно снять выгрузкой Lua.' end
    end
    imgui.TextWrapped(m.help)
    end
    if not live then
        imgui.TextWrapped('После устранения причины выполни полный перезапуск игры.')
        if imgui.Button('Диагностика##'..m.id)then tab=10 end
    end
    if m.error then imgui.TextWrapped('Ошибка: '..m.error) end
    imgui.Spacing()
    for _,action in ipairs(m.actions) do
        if imgui.Button(action[1],imgui.ImVec2(260,35)) then local command=action[2];defer(function()runAction(m,command)end) end
    end
    imgui.Spacing();imgui.Separator()
    if live and host then
        local drawn,err=host:draw(m.id)
        if err then m.error=err;imgui.TextWrapped('Панель остановлена: '..tostring(err))
        elseif not drawn then imgui.TextWrapped('Этот модуль работает прямо в игровых окнах; отдельная панель ему не нужна.')end
    end
end

local function metric(label,value,width)
    imgui.BeginChild('##metric'..label,imgui.ImVec2(width,70),true,imgui.WindowFlags.NoScrollbar)
    imgui.TextColored(quiet,label)
    imgui.TextColored(accent,value)
    imgui.EndChild()
end
local function drawHome()
    drawHero(false)
    local n,failed=0,0;for _,m in ipairs(modules)do
        if findModule(m)then n=n+1 end
        local item=host and host.items[m.id];if m.error or(item and item.error)then failed=failed+1 end
    end
    if failed>0 then
        imgui.TextColored(imgui.ImVec4(1,0.55,0.65,1),'Модулей с ошибками: '..failed..'. Остальные инструменты доступны.')
        if imgui.Button('Открыть диагностику')then tab=10 end
    end
    local width=math.max(250,imgui.GetContentRegionAvail().x)
    local cell=(width-24)/3
    metric('МОДУЛИ',n..' / 7 загружено',cell);imgui.SameLine()
    metric('ТВОЙ СЕРВЕР',servers[cfg.server+1],cell);imgui.SameLine()
    metric('БЫСТРОЕ МЕНЮ',keyName(),cell)
    imgui.Spacing()
    if headingFont then imgui.PushFont(headingFont)end
    imgui.Text('Всё для твоей игры')
    if headingFont then imgui.PopFont()end
    imgui.TextColored(quiet,'Выбирай инструмент — управление без лишних команд.')
    local columns=width>=500 and 2 or 1
    local cardWidth=(width-(columns-1)*12)/columns
    for i,m in ipairs(modules)do
        local live=findModule(m)~=nil
        imgui.PushStyleColor(imgui.Col.ChildBg,imgui.ImVec4(0.065,0.06,0.14,0.92))
        imgui.BeginChild('##card'..m.id,imgui.ImVec2(cardWidth,132),true,imgui.WindowFlags.NoScrollbar)
        imgui.TextColored(accent,string.format('%02d',i)..' / '..m.title)
        imgui.TextColored(live and imgui.ImVec4(0.40,0.87,0.68,1)or quiet,live and 'Загружен' or 'Не загружен')
        if imgui.Button('Открыть раздел##'..m.id,imgui.ImVec2(math.max(120,cardWidth-28),32))then tab=i end
        imgui.EndChild();imgui.PopStyleColor()
        if i%columns~=0 and i<#modules then imgui.SameLine()end
    end
    imgui.Spacing();imgui.TextWrapped('Инвентарь работает в игровых окнах. Истории и настройки встроены во вкладки SHEVA_Helper.')
end
local localPrices={rows={},error='',loaded=false,page=1,filtered={},lastFilter=nil}
local priceFoldMap={}
do
    local upper='АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
    local lower='абвгдеёжзийклмнопрстуфхцчшщъыьэюя'
    for i=1,#upper,2 do priceFoldMap[upper:sub(i,i+1)]=lower:sub(i,i+1)end
end
local function priceFold(text)
    return tostring(text):gsub('[\194-\223][\128-\191]',priceFoldMap):lower()
end
local function loadLocalPrices()
    localPrices.loaded=true;localPrices.error='';localPrices.rows={};localPrices.lastFilter=nil
    local db,recovered=readJsonFile(root..'/prices.json',8*1024*1024)
    if not db then localPrices.error='Сохранённая база не найдена или повреждена. Новые цены не выдумываются.';return end
    if recovered then localPrices.error='Показана резервная копия базы. Обрати внимание на дату.'end
    for _,row in pairs(db)do
        if type(row)=='table'and type(row.name)=='string'and #row.name<=240 and not row.name:find('[%c]')and type(row.price)=='number'and row.price==row.price and row.price>=0 and row.price<=1000000000000000 then
            localPrices.rows[#localPrices.rows+1]={name=row.name,key=priceFold(row.name),price=row.price,currency=tostring(row.currency or 'sa'):sub(1,12):lower(),updated=tostring(row.updated or 'не указано'):sub(1,80)}
        end
    end
    table.sort(localPrices.rows,function(a,b)return a.key<b.key end)
end

local plans={version=1,active=1,sets={{name='Мой сет',items={}}}}
local plansLoaded=false
local plansDirty=false
local planNameBuffer=imgui.new.char[128]()
local planItemBuffer=imgui.new.char[256]()
local planPriceBuffer=imgui.new.char[48]()
local planBufferIndex=nil
local planCurrency='sa'
local deletePlanArmed=false
local function validMoney(n)return type(n)=='number'and n==n and n>=0 and n<=1000000000000000 end
local function cleanName(value,max)
 if type(value)~='string'then return nil end
 value=value:gsub('^%s+',''):gsub('%s+$','')
 if #value<1 or #value>max or value:find('[%c#]')then return nil end
 return value
end
local function loadPlans()
 plansLoaded=true
 local data,recovered=readJsonFile(root..'/sets.json',1048576)
 if not data or type(data.sets)~='table'then return end
 local sets={}
 for _,set in ipairs(data.sets)do
  if #sets>=20 then break end
  local name=type(set)=='table'and cleanName(set.name,120)
  if name and type(set.items)=='table'then
   local items={}
   for _,item in ipairs(set.items)do
    if #items>=60 then break end
    local itemName=type(item)=='table'and cleanName(item.name,240)
    if itemName and validMoney(item.price)and type(item.quantity)=='number'and item.quantity>=1 and item.quantity<=999
     and item.quantity==math.floor(item.quantity)and type(item.currency)=='string'and item.currency:match('^[%w_]+$')and #item.currency<=12 then
     items[#items+1]={name=itemName,price=item.price,quantity=item.quantity,currency=item.currency:lower(),updated=tostring(item.updated or 'Вручную'),source=item.source=='cache'and'cache'or'manual'}
    end
   end
   sets[#sets+1]={name=name,items=items}
  end
 end
 if #sets>0 then
  plans.sets=sets
  plans.active=type(data.active)=='number'and data.active==data.active and math.max(1,math.min(#sets,math.floor(data.active)))or 1
 end
 if recovered then feedback='Сеты восстановлены из резервной копии.';log(feedback)end
 planBufferIndex=nil
end
local function savePlans()
 plansDirty=true
 local ok,err=writeJsonFile(root..'/sets.json',plans)
 if not ok then feedback=err;log(err)else plansDirty=false end
 return ok
end
local function currentPlan()
 if not plansLoaded then loadPlans()end
 return plans.sets[plans.active]
end
local function planTotals(set)
 local totals={}
 for _,item in ipairs(set.items)do totals[item.currency]=(totals[item.currency]or 0)+item.price*item.quantity end
 return totals
end
local function addToPlan(row,source)
 local set=currentPlan();local name=cleanName(row.name,240)
 if not name or not validMoney(row.price)then feedback='Укажи название и неотрицательную цену.';return false end
 local currency=tostring(row.currency or 'sa'):lower()
 if #currency>12 or not currency:match('^[%w_]+$')then feedback='Неизвестная валюта.';return false end
 for _,item in ipairs(set.items)do
  if priceFold(item.name)==priceFold(name)and item.currency==currency then
   if item.quantity>=999 then feedback='Максимум 999 штук в строке.';return false end
   item.quantity=item.quantity+1;local ok=savePlans();return ok
  end
 end
 if #set.items>=60 then feedback='В одном сете максимум 60 строк.';return false end
 set.items[#set.items+1]={name=name,price=row.price,quantity=1,currency=currency,updated=tostring(row.updated or 'Вручную'),source=source=='cache'and'cache'or'manual'}
 local ok=savePlans();if ok then feedback='Добавлено в «'..set.name..'».'end
 return ok
end
local function drawMarket()
    section('Цены SHEVA_Helper','Сохранённые средние цены. Это справочник, а не список актуальных предложений лавок.')
    if not localPrices.loaded then defer(loadLocalPrices)end
    imgui.PushItemWidth(360);imgui.InputTextWithHint('##item','Название товара',query,ffi.sizeof(query));imgui.PopItemWidth()
    if imgui.Button('Обновить из сохранённой базы')then defer(loadLocalPrices)end
    if localPrices.error~=''then imgui.TextWrapped(localPrices.error)end
    imgui.TextDisabled('Предметов: '..#localPrices.rows..'. Проверяй дату: сохранённая цена может устареть.')
    local filter=priceFold(ffi.string(query))
    if filter~=localPrices.lastFilter then
        localPrices.filtered={};localPrices.page=1;localPrices.lastFilter=filter
        for _,row in ipairs(localPrices.rows)do if filter==''or row.key:find(filter,1,true)then localPrices.filtered[#localPrices.filtered+1]=row end end
    end
    local pageCount=math.max(1,math.ceil(#localPrices.filtered/50))
    if imgui.Button('Назад##pricePage')then localPrices.page=math.max(1,localPrices.page-1)end;imgui.SameLine()
    imgui.Text('Страница '..localPrices.page..' / '..pageCount..' · найдено '..#localPrices.filtered);imgui.SameLine()
    if imgui.Button('Далее##pricePage')then localPrices.page=math.min(pageCount,localPrices.page+1)end
    imgui.Columns(4,'##localPrices',true)
    imgui.Text('Предмет');imgui.NextColumn();imgui.Text('Средняя цена');imgui.NextColumn();imgui.Text('Обновлено');imgui.NextColumn();imgui.Text('В сет');imgui.NextColumn();imgui.Separator()
    local first=(localPrices.page-1)*50+1
    for index=first,math.min(first+49,#localPrices.filtered)do
        local row=localPrices.filtered[index]
        imgui.TextWrapped(row.name);imgui.NextColumn();imgui.Text(string.format('%.0f',row.price)..' '..row.currency);imgui.NextColumn();imgui.Text(row.updated);imgui.NextColumn()
        if imgui.Button('+ В сет##cached'..index)then local value=row;defer(function()addToPlan(value,'cache')end)end
        imgui.NextColumn()
    end
    imgui.Columns(1)
end
local function drawSets()
    section('Сеты SHEVA_Helper','Планируй состав и бюджет внутри помощника. Это список с оценкой стоимости, без 3D-примерки и изменения вещей в игре.')
    local set=currentPlan()
    if plansDirty then
        imgui.TextColored(imgui.ImVec4(1,0.55,0.65,1),'Есть несохранённые изменения. Не закрывай игру до сохранения.')
        if imgui.Button('Повторить сохранение сета')then savePlans()end
    end
    if planBufferIndex~=plans.active then ffi.copy(planNameBuffer,set.name);planBufferIndex=plans.active;deletePlanArmed=false end
    if imgui.BeginCombo('Сохранённые сеты',set.name)then
        for i,value in ipairs(plans.sets)do
            if imgui.Selectable(value.name..'##plan'..i,plans.active==i)then plans.active=i;planBufferIndex=nil;savePlans()end
        end
        imgui.EndCombo()
    end
    if imgui.Button('Новый сет')then
        if #plans.sets<20 then
            plans.sets[#plans.sets+1]={name='Новый сет '..(#plans.sets+1),items={}};plans.active=#plans.sets;planBufferIndex=nil;savePlans()
        else feedback='Можно сохранить максимум 20 сетов.'end
    end
    imgui.SameLine()
    if imgui.Button('Добавить предметы из справочника')then tab=8 end
    imgui.PushItemWidth(250);imgui.InputTextWithHint('##planName','Название сета',planNameBuffer,ffi.sizeof(planNameBuffer));imgui.PopItemWidth()
    imgui.SameLine()
    if imgui.Button('Переименовать')then
        local name=cleanName(ffi.string(planNameBuffer),120)
        if name then set.name=name;savePlans()else feedback='Название: до 120 байт, без управляющих символов и #.'end
    end
    if imgui.CollapsingHeader('Добавить предмет вручную')then
        imgui.PushItemWidth(300);imgui.InputTextWithHint('##planItem','Название предмета',planItemBuffer,ffi.sizeof(planItemBuffer));imgui.PopItemWidth()
        imgui.PushItemWidth(200);imgui.InputTextWithHint('##planPrice','Оценка цены за штуку',planPriceBuffer,ffi.sizeof(planPriceBuffer));imgui.PopItemWidth()
        for _,currency in ipairs({'sa','vc'})do
            if imgui.Button(currency..'##planCurrency')then planCurrency=currency end;imgui.SameLine()
        end
        imgui.NewLine();imgui.TextDisabled('Валюта: '..planCurrency..'. Твоя оценка, не рыночная котировка.')
        if imgui.Button('Добавить в список')then
            addToPlan({name=ffi.string(planItemBuffer),price=tonumber((ffi.string(planPriceBuffer):gsub('%s',''))),currency=planCurrency},'manual')
        end
    end
    imgui.Spacing();imgui.Separator()
    local removeIndex
    imgui.Columns(5,'##setItems',true)
    for _,name in ipairs({'Предмет','Оценка / шт.','Количество','Источник','Действия'})do imgui.Text(name);imgui.NextColumn()end
    imgui.Separator()
    for i,item in ipairs(set.items)do
        imgui.TextWrapped(item.name);imgui.NextColumn()
        imgui.Text(string.format('%.0f',item.price)..' '..item.currency);imgui.NextColumn()
        imgui.Text(tostring(item.quantity));imgui.NextColumn()
        imgui.TextWrapped(item.source=='cache'and('База: '..item.updated)or'Твоя оценка');imgui.NextColumn()
        if imgui.Button('-##quantity'..i)and item.quantity>1 then item.quantity=item.quantity-1;savePlans()end;imgui.SameLine()
        if imgui.Button('+##quantity'..i)and item.quantity<999 then item.quantity=item.quantity+1;savePlans()end
        if imgui.Button('Убрать##item'..i)then removeIndex=i end
        imgui.NextColumn()
    end
    imgui.Columns(1)
    if removeIndex then table.remove(set.items,removeIndex);savePlans()end
    local totals=planTotals(set)
    for _,currency in ipairs({'sa','vc'})do if totals[currency]then imgui.TextColored(accent,'Ориентир: '..string.format('%.0f',totals[currency])..' '..currency)end end
    for currency,value in pairs(totals)do if currency~='sa'and currency~='vc'then imgui.TextColored(accent,'Ориентир: '..string.format('%.0f',value)..' '..currency)end end
    if #set.items==0 then imgui.TextWrapped('Пока пусто. Добавь предмет из справочника или укажи свой.')end
    imgui.TextDisabled('Валюты считаются отдельно. Сохранённые средние цены могут устареть.')
    if imgui.Button('Скопировать список')then
        if type(setClipboardText)=='function'then
            local lines={set.name}
            for _,item in ipairs(set.items)do lines[#lines+1]=item.name..' x'..item.quantity..' — '..string.format('%.0f',item.price*item.quantity)..' '..item.currency end
            setClipboardText(cp(table.concat(lines,'\n')));feedback='Список скопирован.'
        else feedback='Буфер обмена недоступен.'end
    end
    imgui.SameLine()
    if imgui.Button(deletePlanArmed and 'Подтвердить удаление сета' or 'Удалить этот сет')then
        if not deletePlanArmed then deletePlanArmed=true else
            table.remove(plans.sets,plans.active)
            if #plans.sets==0 then plans.sets={{name='Мой сет',items={}}}end
            plans.active=math.min(plans.active,#plans.sets);planBufferIndex=nil;savePlans()
        end
    end
end
local function drawServers()
    section('Серверы и очереди','Онлайн и очередь серверов. Обновление раз в минуту, пока открыт этот раздел.')
    if imgui.Button(monitor.busy and 'Загрузка...' or 'Обновить')then defer(refreshServers)end
    if monitor.received>0 then
        local age=math.max(0,os.time()-monitor.received)
        imgui.TextColored(age>120 and accent or quiet,'Получено: '..os.date('%d.%m %H:%M:%S',monitor.received)..' ('..math.floor(age/60)..' мин. назад)')
        imgui.TextDisabled('Обновление у источника: '..monitor.sourceAge)
    else imgui.TextDisabled('Список ещё не загружен. При недоступности источника повтори позже.')end
    if monitor.error~=''then imgui.TextWrapped('Не обновлено: '..monitor.error)end
    for _,row in ipairs(monitor.rows)do
        if row.id==cfg.server then
            imgui.TextColored(accent,'Твой сервер: '..row.name..' — '..row.online..'/'..row.capacity..'; очередь: '..row.queue)
            break
        end
    end
    imgui.PushItemWidth(240);imgui.InputTextWithHint('##serverFilter','Поиск сервера',serverFilter,ffi.sizeof(serverFilter));imgui.PopItemWidth()
    imgui.SameLine();if imgui.Button(monitor.byQueue and 'Порядок: очередь' or 'Порядок: номер')then monitor.byQueue=not monitor.byQueue end
    local filter=ffi.string(serverFilter):lower()
    local rows={};for _,r in ipairs(monitor.rows)do if r.name:lower():find(filter,1,true)then rows[#rows+1]=r end end
    table.sort(rows,function(a,b)if monitor.byQueue and a.queue~=b.queue then return a.queue>b.queue end return a.id<b.id end)
    imgui.Separator();imgui.Columns(3,'##servers',true)
    imgui.Text('Сервер');imgui.NextColumn();imgui.Text('Онлайн / мест');imgui.NextColumn();imgui.Text('Очередь');imgui.NextColumn();imgui.Separator()
    for _,r in ipairs(rows)do
        local label=(r.id==0 and 'VC' or r.id>=100 and 'M'..(r.id-100)or tostring(r.id))..'  '..r.name
        if r.id==cfg.server then imgui.TextColored(accent,label)else imgui.Text(label)end
        imgui.NextColumn();imgui.Text(r.online..' / '..r.capacity);imgui.NextColumn()
        imgui.TextColored(r.queue>0 and accent or quiet,tostring(r.queue));imgui.NextColumn()
    end
    imgui.Columns(1);imgui.Separator();imgui.TextDisabled('Очередь сервера, а не твоя персональная позиция. Источники перечислены в сведениях о программе.')
end

local function openArzPriceTable()
    tab=8;opened[0]=true;return true
end
local function registerArzAlias()
    if type(sampIsChatCommandDefined)=='function'and sampIsChatCommandDefined('crrhh')then
        say('/crrhh уже занята другим скриптом. Кнопка таблицы в меню остаётся доступной.');return false
    end
    sampRegisterChatCommand('crrhh',function()defer(openArzPriceTable)end)
    return true
end
local function drawArzTable()
    drawMarket()
end

-- Updates use a publisher-controlled HTTPS manifest. No remote Lua is evaluated.
local releaseVersion='2.9.1-embedded-beta'
local defaultManifestUrl='https://raw.githubusercontent.com/xromxgame-lgtm/-/shva-updates/SHVA_Helper/manifest.json'
local updater={state='Ожидание проверки обновлений.',busy=false,available=false,seq=0,lastCheck=0}
local function readFile(path,limit)
 local f=io.open(path,'rb');if not f then return nil end;local d=f:read(limit and(limit+1)or '*a');f:close();return d
end
local function sha256(data)
 local bit=require 'bit'
 local band,bxor,bnot,ror,rshift=bit.band,bit.bxor,bit.bnot,bit.ror,bit.rshift
 local K={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
 local H={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
 local bits=#data*8
 data=data..'\128'..string.rep('\0',(55-#data)%64)..string.char(0,0,0,0,band(rshift(bits,24),255),band(rshift(bits,16),255),band(rshift(bits,8),255),band(bits,255))
 for pos=1,#data,64 do
  local w={}
  for i=0,15 do local a,b,c,d=data:byte(pos+i*4,pos+i*4+3);w[i]=a*16777216+b*65536+c*256+d end
  for i=16,63 do local a,b=w[i-15],w[i-2];w[i]=bit.tobit(w[i-16]+bxor(ror(a,7),ror(a,18),rshift(a,3))+w[i-7]+bxor(ror(b,17),ror(b,19),rshift(b,10)))end
  local a,b,c,d,e,f,g,h=unpack(H)
  for i=0,63 do
   local t=bit.tobit(h+bxor(ror(e,6),ror(e,11),ror(e,25))+bxor(band(e,f),band(bnot(e),g))+K[i+1]+w[i])
   local u=bit.tobit(bxor(ror(a,2),ror(a,13),ror(a,22))+bxor(band(a,b),band(a,c),band(b,c)))
   h,g,f,e,d,c,b,a=g,f,e,bit.tobit(d+t),c,b,a,bit.tobit(t+u)
  end
  local v={a,b,c,d,e,f,g,h};for i=1,8 do H[i]=bit.tobit(H[i]+v[i])end
 end
 local out={};for i=1,8 do out[i]=bit.tohex(H[i])end;return table.concat(out)
end
local function httpsOrigin(url)
 if type(url)~='string'or #url>2048 or url:find('[%s%c]')then return nil end
 return url:match('^(https://[%w%.%-]+)[:/]')
end
local function versionParts(v)
 if type(v)~='string' or #v>80 then return nil end
 local a,b,c=v:match('^(%d+)%.(%d+)%.(%d+)[%w%.%-]*$')
 if not a then return nil end
 return {tonumber(a),tonumber(b),tonumber(c)}
end
local function newer(v)
 local candidate,current=versionParts(v),versionParts(releaseVersion)
 if not candidate then return false end
 for i=1,3 do if candidate[i]~=current[i]then return candidate[i]>current[i]end end
 return false
end
local function beginUpdateDownload(url,kind)
 if updater.busy then return end
 updater.seq=updater.seq+1;local seq=updater.seq
 updater.busy=true;updater.kind=kind;updater.done=false;updater.started=os.time()
 updater.path=root..'/update-'..kind..'-'..seq..'.tmp'
 local path=updater.path;os.remove(path)
 local ok,err=pcall(downloadUrlToFile,url,updater.path,function(_,status)
  if status==moonloader.download_status.STATUSEX_ENDDOWNLOAD then
   if updater.seq==seq and updater.busy then updater.done=true else os.remove(path)end
  end
 end)
 if not ok then updater.busy=false;updater.state='Не удалось начать загрузку.';log(tostring(err))end
end
local function checkUpdates()
 if updater.busy then return end
 if type(downloadUrlToFile)~='function'then updater.state='В этой сборке MoonLoader загрузка недоступна.';return end
 if os.time()-updater.lastCheck<30 then return end
 updater.lastCheck=os.time()
 local raw=readFile(root..'/updates.json');local ok,d=pcall(decodeJson,raw or '')
 local url=defaultManifestUrl
 if raw then
  if not ok or type(d)~='table'or not httpsOrigin(d.manifestUrl)then updater.state='Некорректный updates.json. Проверь адрес источника.';return end
  url=d.manifestUrl
 end
 updater.origin=httpsOrigin(url);updater.available=false
 updater.state='Проверяем новую версию…';beginUpdateDownload(url,'manifest')
end

local bundlePaths={['SHVA_Helper.lua']=true,['Cripto_Shewa/module_host.lua']=true,['Cripto_Shewa/assets/space_city.png']=true}
for _,m in ipairs(modules)do bundlePaths['Cripto_Shewa/modules/'..m.id..'.lua']=true end
local function validateBundle(m)
 if type(m.files)~='table'or #m.files<1 or #m.files>11 then return false end
 local seen={};local total=0
 for _,file in ipairs(m.files)do
  if type(file)~='table'or not bundlePaths[file.path]or seen[file.path]or httpsOrigin(file.url)~=updater.origin
   or type(file.sha256)~='string'or #file.sha256~=64 or file.sha256:find('[^%x]')
   or type(file.size)~='number'or file.size<1 or file.size>16777216 or file.size~=math.floor(file.size)then return false end
  seen[file.path]=true;total=total+file.size
 end
 return seen['SHVA_Helper.lua']and total<=33554432
end
local function bundleTarget(path)
 if path=='SHVA_Helper.lua'then return thisScript().path end
 return getWorkingDirectory()..'/'..path
end
local function writeUpdateFile(path,data)
 local f=io.open(path,'wb');if not f then return false end
 local ok=f:write(data);local closed=f:close();return ok~=nil and closed~=nil
end
local function commitBundle()
 local files=updater.bundle.files;local completed={}
 -- Stage and back up every file before replacing anything.
 for i,file in ipairs(files)do
  local target=bundleTarget(file.path);local previous=readFile(target,16777216)
  if previous and #previous>16777216 then updater.state='Прежний файл слишком большой. Обновление отменено.';return end
  local entry={target=target,old=previous};completed[#completed+1]=entry
  if previous and not writeUpdateFile(target..'.bak',previous)then updater.state='Не удалось сохранить копии комплекта. Ничего не заменено.';return end
  if not writeUpdateFile(target..'.new',updater.bundle.data[i])then updater.state='Не удалось подготовить комплект. Ничего не заменено.';return end
 end
 local changed={}
 for _,entry in ipairs(completed)do
  local ok=true
  if entry.old then
   os.remove(entry.target..'.previous');ok=os.rename(entry.target,entry.target..'.previous')
  end
  if ok then
   changed[#changed+1]=entry
   ok=os.rename(entry.target..'.new',entry.target)
  end
  if not ok then
   local recovered=true
   for i=#changed,1,-1 do
    local old=changed[i]
    os.remove(old.target)
    if old.old and not os.rename(old.target..'.previous',old.target)then recovered=false end
   end
   updater.state=recovered and 'Установка комплекта отменена; прежние файлы восстановлены.'or'Ошибка восстановления комплекта. Закрой игру и восстанови файлы из .bak.'
   updater.available=false;return
  end
 end
 for _,entry in ipairs(completed)do os.remove(entry.target..'.previous');os.remove(entry.target..'.new')end
 updater.available=false;updater.bundle=nil
 updater.state='Комплект обновлён. Полностью перезапусти игру для применения.'
end
local function downloadBundleFile()
 local batch=updater.bundle
 local file=batch.files[batch.index]
 updater.state='Обновление комплекта: '..batch.index..' / '..#batch.files..' — '..file.path
 beginUpdateDownload(file.url,'bundle')
end
local function installUpdate()
 if not updater.available or updater.busy then return end
 if updater.manifest.files then
  updater.bundle={files=updater.manifest.files,index=1,data={}};downloadBundleFile();return
 end
 updater.state='Загружаем '..updater.manifest.version..'…'
 beginUpdateDownload(updater.manifest.url,'script')
end
local function pollUpdates()
 if not updater.busy then return end
 if os.time()-updater.started>30 then updater.busy=false;updater.seq=updater.seq+1;updater.state='Сервер обновлений не ответил. Попробуй позже.';return end
 if not updater.done then return end
 updater.busy=false
 local limit=updater.kind=='bundle'and 16777216 or 2097152
 local data=readFile(updater.path,limit);os.remove(updater.path)
 if not data or #data==0 or #data>limit then updater.state='Получен пустой или слишком большой файл.';return end
 if updater.kind=='manifest'then
  local ok,m=pcall(decodeJson,data)
  if ok and type(m)=='table'and m.files and m.bundleVersion then m.version=m.bundleVersion end
  local valid=ok and type(m)=='table'and versionParts(m.version)
  if valid then
   if m.files then valid=validateBundle(m)
   else valid=type(m.sha256)=='string'and #m.sha256==64 and not m.sha256:find('[^%x]')and httpsOrigin(m.url)==updater.origin end
  end
  if not valid then updater.state='Некорректный файл версии.';return end
  if not newer(m.version)then updater.state='Новой версии нет. Установлено: '..releaseVersion..'. Источник: '..m.version;return end
  updater.manifest=m;updater.available=true;updater.state='Доступна новая версия: '..m.version
  say('Доступно обновление '..m.version..'. Кнопка — в настройках SHEVA_Helper.')
 elseif updater.kind=='bundle'then
  local batch=updater.bundle;local file=batch.files[batch.index]
  local ok,hash=pcall(sha256,data)
  if not ok or #data~=file.size or hash~=file.sha256:lower()then updater.state='Комплект повреждён. Установленные файлы не изменены.';updater.bundle=nil;return end
  if file.path:match('%.lua$')and not loadstring(data,'update/'..file.path)then updater.state='Ошибка Lua в комплекте. Файлы не изменены.';updater.bundle=nil;return end
  batch.data[batch.index]=data;batch.index=batch.index+1
  if batch.index>#batch.files then commitBundle()else downloadBundleFile()end
 else
  local ok,hash=pcall(sha256,data)
  if not ok or hash~=updater.manifest.sha256:lower()then updater.state='Проверка SHA-256 не пройдена. Скрипт не изменён.';return end
  if not loadstring(data,'SHEVA_Helper update')then updater.state='В обновлении ошибка Lua. Скрипт не изменён.';return end
  local target=thisScript().path
  local old=readFile(target);if not old then updater.state='Не удалось прочитать текущий скрипт.';return end
  local function write(path,bytes)local f=io.open(path,'wb');if not f then return false end;local ok=f:write(bytes);local closed=f:close();return ok~=nil and closed~=nil end
  if not write(target..'.bak',old)or not write(target..'.new',data)then updater.state='Не удалось сохранить резервную копию или обновление.';return end
  local previous=target..'.previous';os.remove(previous)
  local moved=os.rename(target,previous)
  if not moved then updater.state='Не удалось заменить файл. Обновление отменено.';return end
  local installed=os.rename(target..'.new',target)
  if not installed then
   local restored=os.rename(previous,target)
   if restored then updater.state='Замена отменена; восстановлена предыдущая версия.'
   else updater.available=false;updater.state='Не удалось восстановить файл. Закрой игру и восстанови SHVA_Helper.lua из .bak.';log('Update rollback failed: '..target)end
   return
  end
  os.remove(previous);updater.available=false;updater.state='Обновление установлено. Перезапусти игру для применения.'
 end
end

local function diagnosticText()
    local lines={'SHEVA_Helper '..releaseVersion,os.date('%Y-%m-%d %H:%M:%S'),'Клавиши: '..keyName()}
    local width,height=getScreenResolution();lines[#lines+1]='Экран: '..width..'x'..height
    for _,m in ipairs(modules)do
        local item=host and host.items[m.id]
        local status=item and(item.error or(item.started and'запущен'or'не запущен'))or'не загружен'
        lines[#lines+1]=m.title..': '..status
    end
    lines[#lines+1]='Сохранённых цен: '..#localPrices.rows
    lines[#lines+1]='Сохранённых сетов: '..#plans.sets
    lines[#lines+1]='Обновления: '..updater.state
    lines[#lines+1]='Очереди: '..(monitor.error~=''and monitor.error or tostring(#monitor.rows)..' серверов')
    return table.concat(lines,'\n')
end
local function exportDiagnostics()
    local text=diagnosticText()
    local f=io.open(root..'/diagnostic.txt','wb')
    if not f then feedback='Не удалось записать отчёт диагностики.';return false end
    local wrote=f:write(text);local closed=f:close()
    if not wrote or not closed then feedback='Ошибка записи отчёта диагностики.';return false end
    if type(setClipboardText)=='function'then setClipboardText(cp(text));feedback='Отчёт сохранён и скопирован. Его можно вставить в сообщение.'
    else feedback='Отчёт сохранён: config/Cripto_Shewa/diagnostic.txt'end
    return true
end
local function drawSettings()
    if settingsDirty then
        imgui.TextColored(imgui.ImVec4(1,0.55,0.65,1),'Настройки изменены, но не сохранены на диск.')
        if imgui.Button('Повторить сохранение настроек')then save()end
    end
    imgui.TextColored(accent,'Обновления SHEVA_Helper · '..releaseVersion)
    imgui.TextWrapped(updater.state)
    if imgui.Button('Проверить обновления')then defer(checkUpdates)end
    if updater.available and not updater.busy then imgui.SameLine();if imgui.Button('Обновить до '..updater.manifest.version)then defer(installUpdate)end end
    imgui.TextWrapped('Проверка при входе автоматическая. Обновление комплекта — кнопкой, с проверкой каждого файла и резервными копиями. Применяется после перезапуска игры.')
    imgui.Separator()
    section('Настройки','Сочетание открытия можно изменить. F-клавиши не принимаются, чтобы не занимать управление игрой.')
    imgui.TextColored(accent,'SHEVA_Helper / SPACE EDITION')
    imgui.Spacing()
    local motion=imgui.new.bool(cfg.animation)
    if imgui.Checkbox('Мягкая анимация и свечение',motion)then cfg.animation=motion[0];save()end
    local art=imgui.new.bool(cfg.artwork)
    if imgui.Checkbox('Атмосферный фон',art)then cfg.artwork=art[0];save()end
    imgui.TextColored(quiet,'Цвет акцентов')
    for _,option in ipairs({{'Золото','amber'},{'Фиолетовый','violet'},{'Мята','teal'}})do
        if imgui.Button(option[1])then cfg.palette=option[2];theme();save()end
        imgui.SameLine()
    end
    imgui.NewLine();imgui.Spacing()
    imgui.Text('Сейчас: '..keyName())
    if imgui.Button(binding and 'Нажми сочетание... Esc — отмена' or 'Изменить сочетание',imgui.ImVec2(340,36))then binding=true end
    imgui.Spacing();imgui.TextWrapped('Рекомендуется сочетание с Ctrl, Shift или Alt. Без модификаторов назначение не сохраняется.')
    imgui.Separator()
    if imgui.Button('Скопировать диагностику')then defer(exportDiagnostics)end
    imgui.TextWrapped('Отчёт содержит версию, состояния модулей и ошибки. Сам никуда не отправляется.')
    imgui.Separator();imgui.TextWrapped('О программе. Разработчики исходных модулей: ArzHub. Оформление, единое окно и интеграция: SHEVA_Helper. Исходники и версии указаны в SOURCES.txt.')
    imgui.TextWrapped('Старая база средних цен и настройки модулей не удаляются. Источники данных: arzhub.top (каталоги и мониторинг серверов). Сайты автоматически не открываются.')
end

local function navButton(label,value)
    local selected=tab==value
    if selected then imgui.PushStyleColor(imgui.Col.Button,imgui.ImVec4(accent.x*0.23,accent.y*0.23,accent.z*0.23,1))end
    if imgui.Button(label..'##nav'..value,imgui.ImVec2(-1,32))then tab=value end
    if selected then imgui.PopStyleColor()end
end
imgui.OnFrame(function()return opened[0]end,function(player)
    player.HideCursor=false;player.LockPlayer=true
    if themeDirty then theme();themeDirty=false end
    local sw,sh=getScreenResolution()
    imgui.SetNextWindowSize(imgui.ImVec2(math.min(1180,sw-40),math.min(800,sh-40)),imgui.Cond.FirstUseEver)
    if imgui.Begin(cfg.name..'###CriptoShewaMain',opened,imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoTitleBar)then
        local draw=imgui.GetWindowDrawList()
        local wp=imgui.GetWindowPos();local ws=imgui.GetWindowSize()
        if cfg.artwork and artwork then
            local ratio=ws.x/ws.y
            local uCrop=math.min(1,ratio/(1664/936))
            local vCrop=math.min(1,(1664/936)/ratio)
            draw:AddImage(artwork,wp,imgui.ImVec2(wp.x+ws.x,wp.y+ws.y),imgui.ImVec2((1-uCrop)/2,(1-vCrop)/2),imgui.ImVec2((1+uCrop)/2,(1+vCrop)/2),imgui.GetColorU32Vec4(imgui.ImVec4(1,1,1,0.46)))
            draw:AddRectFilled(wp,imgui.ImVec2(wp.x+ws.x,wp.y+ws.y),imgui.GetColorU32Vec4(imgui.ImVec4(0.025,0.025,0.07,0.67)),12)
        end

        draw:AddRectFilled(imgui.ImVec2(wp.x+15,wp.y+1),imgui.ImVec2(wp.x+ws.x-15,wp.y+3),imgui.GetColorU32Vec4(imgui.ImVec4(accent.x,accent.y,accent.z,0.70*pulseAlpha())),2)
        imgui.TextColored(accent,'SHEVA')
        imgui.SameLine();imgui.TextColored(quiet,'/ HELPER   •   SPACE EDITION')
        imgui.SameLine(math.max(300,ws.x-180));if imgui.SmallButton('Настройки##top')then tab=10 end
        imgui.SameLine();if imgui.SmallButton('X##close')then opened[0]=false end
        imgui.Separator()
        local navWidth=ws.x<900 and 175 or 205
        imgui.BeginChild('##nav',imgui.ImVec2(navWidth,-32),true)
        imgui.TextColored(quiet,'ЛИЧНЫЙ ЦЕНТР')
        navButton('Обзор',0)
        imgui.Spacing();imgui.TextColored(quiet,'ИНСТРУМЕНТЫ')
        for i,m in ipairs(modules)do navButton(string.format('%02d',i)..'  '..m.title,i)end
        imgui.Spacing();imgui.TextColored(quiet,'РЫНОК И СЕРВЕРА')
        navButton('Поиск цен',8);navButton('Мои сеты',9);navButton('Очереди серверов',11)
        imgui.Spacing();navButton('Настройки',10)
        imgui.EndChild();imgui.SameLine()
        imgui.BeginChild('##content',imgui.ImVec2(0,-32),false)
        if tab~=0 then drawHero(true);imgui.Spacing()end
        if tab==0 then drawHome()elseif tab<=7 then drawModule(modules[tab])elseif tab==8 then drawMarket()elseif tab==9 then drawSets()elseif tab==11 then drawServers()elseif tab==12 then drawArzTable()else drawSettings()end
        imgui.EndChild();imgui.Separator()
        imgui.TextColored(quiet,feedback~=''and feedback or(keyName()..'   /   Главное окно   /   2.9.1 EMBEDDED TEST'))
    end
    imgui.End()
end)
function main()
    repeat wait(100)until isSampAvailable()
    if not doesDirectoryExist(root)then createDirectory(root)end
    load();save();loadServerCache();loadLocalPrices();loadPlans();log('SHEVA_Helper 2.9 Embedded startup');updateAccent();themeDirty=true
    checkUpdates()
    registerArzAlias()
    for _,m in ipairs(modules)do if cfg.enabled[m.id]~=false then startModule(m)end end
    local started=0;for _,m in ipairs(modules)do if findModule(m)then started=started+1 end end
    say('Запущено модулей: '..started..'/7. Меню: '..keyName()..'.')
    local last=false
    while true do
        wait(0)
        pollServers()
        pollUpdates()
        if host then
            if opened[0] and tab>=1 and tab<=7 then host:prepare(modules[tab].id)
            elseif host.selected then host:hide()end
        end
        local pending=deferred;deferred={}
        for _,fn in ipairs(pending)do local ok,err=pcall(fn);if not ok then feedback='Ошибка действия: '..tostring(err);log(feedback)end end
        local busy=sampIsChatInputActive()or sampIsDialogActive()or isPauseMenuActive()
        if opened[0]and not binding and not busy and isKeyJustPressed(27)then opened[0]=false end
        if binding and not busy then
            if isKeyJustPressed(27)then binding=false else
                for key=32,254 do
                    if not(key>=112 and key<=123)and key~=160 and key~=161 and key~=162 and key~=163 and key~=164 and key~=165 and isKeyJustPressed(key)then
                        local ctrl,shift,alt=isKeyDown(17),isKeyDown(16),isKeyDown(18)
                        if ctrl or shift or alt then cfg.key=key;cfg.ctrl=ctrl;cfg.shift=shift;cfg.alt=alt;save();feedback='Сочетание сохранено: '..keyName();binding=false;last=true;break end
                    end
                end
            end
        else
            local held=isKeyDown(cfg.key)and(not cfg.ctrl or isKeyDown(17))and(not cfg.shift or isKeyDown(16))and(not cfg.alt or isKeyDown(18))
            if held and not last and not busy then opened[0]=not opened[0]end
            last=held
        end
    end
end
