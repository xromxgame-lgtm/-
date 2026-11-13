script_name('SHVA_Helper')
script_author('SHVA_Helper; modules by ArzHub')
script_version('2.6.1-space-beta')
require 'lib.moonloader'
local moonloader = require 'moonloader'
local imgui = require 'mimgui'
local ffi = require 'ffi'
local encoding = require 'encoding'
encoding.default = 'UTF-8'
local cp = encoding.CP1251
local root = getWorkingDirectory() .. '/config/Cripto_Shewa'
local moduleRoot = getWorkingDirectory() .. '/Cripto_Shewa/modules/'
local cfg = {name = 'SHVA_Helper', key = 72, ctrl = true, shift = true, alt = false, server = 32, mode = 'sell', enabled = {}, animation = true, artwork = true, palette = 'violet', skinVersion = 2}
local modules = {
    {id='inventory-plus', name='Inventory Plus', title='Инвентарь', version='2.8.0', desc='Названия и поиск предметов в лавках, шкафах, складах и багажнике. Сортировка, «Забрать всё», MAX и подсчёт стоимости.', help='Открой инвентарь, лавку или хранилище. Улучшения появляются в исходном окне игры автоматически. «Забрать всё» по описанию автора не применяется к лавкам.', actions={{'Обновить справочник', '/ipreload'}}},
    {id='case-opener',name='Case Opener',title='Кейсы',version='2.3.0',desc='Панель открытия кейсов, история дропа и правила автоматического режима.',help='Открой кейс — панель появится в его интерфейсе. Автоматический режим и правила включаются в панели модуля.',actions={{'История и правила','/caselogs'}}},
    {id='battlepass-helper',name='BattlePass Helper',title='Боевой пропуск',version='1.5.0',desc='Задания боевого пропуска, прогресс, закрепление, скрытие и таймер сброса.',help='Настройки и задания открываются кнопкой ниже. Модуль может использовать собственную F9 — переназначь её в его настройках при конфликте.',actions={{'Задания и настройки','/bp'}}},
    {id='crypto-collector',name='Crypto Collector',title='Криптовалюта',version='2.7.1',desc='Сбор криптовалюты из домов, история, состояния карт и список исключений.',help='Для сбора нужна Флешка майнера. Сбор запускается только твоим нажатием, не при входе в игру.',actions={{'История и настройки','/crstats'},{'Настройки сбора','/crconfig'},{'Начать сбор','/crypto'}}},
    {id='dialog-plus',name='Dialog Plus',title='Диалоги',version='1.3.1',desc='Выбор пунктов цифрами, единая нумерация и MAX в поддерживаемых окнах количества.',help='Работает автоматически в поддерживаемых диалогах. Повторное нажатие цифры может подтвердить выбор — учитывай это при покупке.',actions={}},
    {id='craft-counter',name='Craft Counter',title='Крафт',version='1.5.0',desc='Прогресс крафта, удачные и неудачные попытки, расходы, время и история.',help='Счётчик начинает работать после запуска крафта в игре. История открывается кнопкой ниже.',actions={{'История крафтов','/cchistory'}}},
    {id='auto-spawn',name='Auto Spawn',title='Спавн',version='1.1.0',desc='Сохранённое место спавна с автоматическим выбором после отсчёта.',help='Работает с новым интерфейсом авторизации. Отметь нужное место звёздочкой. Не запускай параллельно AutoSelectSpawnV4.',actions={}}
}
local servers={'Vice-City','Phoenix','Tucson','Scottdale','Chandler','Brainburg','Saint-Rose','Mesa','Red-Rock','Yuma','Surprise','Prescott','Glendale','Kingman','Winslow','Payson','Gilbert','Show-Low','Casa-Grande','Page','Sun-City','Queen-Creek','Sedona','Holiday','Wednesday','Yava','Faraway','Bumble-Bee','Christmas','Mirage','Love','Drake','Space','Home'}
local defaultSet='https://arzset.fun/?v=3&b=.yI7IPUfQgiJDQAAAAAiOgAAFyUIiQ0AAAAAIhMAAB4tInENAAAAAB6sAAAAAAiJDQAAAAAiMh.zAAAIiQ0AAAAAH-cf2R4qCIkNAAAAAB6mKL4AABz8DAAAAAAc7iMZAAAc-wAAAAAAACeKJ1IAB..-ACekBRT..gAnkgPp..4AJ5UD6QF.'
cfg.setUrl=defaultSet
local opened=imgui.new.bool(false)
local query=imgui.new.char[256]()
local appName=imgui.new.char[128]()
local serverFilter=imgui.new.char[96]()
local monitor={rows={},received=0,sourceAge='',error='',busy=false,lastAttempt=0,seq=0,byQueue=false}
local tab=0
local initialized=false
local artwork=nil
local headingFont=nil
local titleFont=nil
local themeDirty=true
local artPath=getWorkingDirectory()..'/Cripto_Shewa/assets/space_city.png'
local binding=false
local deferred={}
local feedback=''
local accent=imgui.ImVec4(1.0,0.74,0.28,1)
local quiet=imgui.ImVec4(0.64,0.68,0.75,1)
local function say(s) sampAddChatMessage('{FFD166}[SHVA_Helper] {FFFFFF}'..cp(s),0xFFFFFF) end
local function log(s)
    local f=io.open(root..'/unified.log','ab')
    if f then f:write(os.date('%Y-%m-%d %H:%M:%S '),s,'\n');f:close() end
end
local function validSet(url) return type(url)=='string' and #url<=4096 and url:match('^https://arzset%.fun/[%w%?&=%.%_%-%%#~]*$')~=nil end
local function save()
    local ok,data=pcall(encodeJson,cfg);if not ok then feedback='Ошибка кодирования настроек.';return end
    local f=io.open(root..'/unified_settings.json','wb');if not f then feedback='Не удалось сохранить настройки.';return end
    f:write(data);f:close()
end
local function load()
    local f=io.open(root..'/unified_settings.json','rb');if not f then return end
    local s=f:read('*a');f:close();local ok,d=pcall(decodeJson,s)
    if not ok or type(d)~='table' then return end
    if type(d.name)=='string' and #d.name>0 and #d.name<80 and d.name~='Cripto_Shewa' then cfg.name=d.name end
    if type(d.key)=='number' and d.key>=32 and d.key<=254 and not(d.key>=112 and d.key<=123) then cfg.key=math.floor(d.key) end
    for _,k in ipairs({'ctrl','shift','alt'}) do if type(d[k])=='boolean' then cfg[k]=d[k] end end
    if type(d.server)=='number' and d.server>=0 and d.server<#servers and d.server==math.floor(d.server) then cfg.server=d.server end
    if d.mode=='sell' or d.mode=='buy' or d.mode=='all' then cfg.mode=d.mode end
    if validSet(d.setUrl) then cfg.setUrl=d.setUrl end
    if type(d.animation)=='boolean'then cfg.animation=d.animation end
    if type(d.artwork)=='boolean'then cfg.artwork=d.artwork end
    if d.skinVersion==2 and(d.palette=='amber'or d.palette=='violet'or d.palette=='teal')then cfg.palette=d.palette end
    if type(d.enabled)=='table' then for _,m in ipairs(modules) do if type(d.enabled[m.id])=='boolean' then cfg.enabled[m.id]=d.enabled[m.id] end end end
end
local function findModule(m)
    local ok,result=pcall(script.find,m.name);if ok then return result end
end
local function startModule(m)
    if findModule(m) then m.error=nil;return true end
    local path=moduleRoot..m.id..'.lua'
    if not doesFileExist(path) then m.error='Не найден файл '..m.id..'.lua';log(m.error);return false end
    local ok,result=pcall(script.load,path)
    if not ok then m.error=tostring(result);log(m.id..': '..m.error);return false end
    m.started=os.time();m.error=nil;log('Загрузка '..m.id);return true
end
local function defer(f) deferred[#deferred+1]=f end
local function runAction(m,command)
    if not findModule(m) then feedback='Модуль не загружен. Проверь журнал.';return end
    if type(sampIsChatCommandDefined)=='function' and not sampIsChatCommandDefined(command:sub(2)) then feedback='Модуль ещё запускается или не зарегистрировал действие.';return end
    if type(sampProcessChatInput)~='function' then feedback='Нужен SAMPFUNCS для локальных действий.';return end
    opened[0]=false
    sampProcessChatInput(command)
end
pcall(ffi.cdef,[[void* __stdcall ShellExecuteA(void* hwnd,const char* operation,const char* file,const char* parameters,const char* directory,int showCmd);]])
local shell=ffi.load('shell32')
local function browser(url)
    if not (url:match('^https://online%.arz%-mcr%.ru/') or validSet(url) or url=='https://arzhub.top/servers') then feedback='Адрес не разрешён.';return end
    local result=shell.ShellExecuteA(nil,'open',url,nil,nil,1)
    if tonumber(ffi.cast('intptr_t',result))<=32 then feedback='Браузер не открылся.' else feedback='Страница открыта в браузере.' end
end
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
    local ok,data=pcall(encodeJson,{rows=monitor.rows,received=monitor.received,sourceAge=monitor.sourceAge})
    if not ok then return end
    local f=io.open(root..'/servers_cache.json','wb');if f then f:write(data);f:close()end
end
local function loadServerCache()
    local f=io.open(root..'/servers_cache.json','rb');if not f then return end
    local data=f:read('*a');f:close();local ok,value=pcall(decodeJson,data)
    if not ok or type(value)~='table'or type(value.rows)~='table'then return end
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
        if not f then monitor.error='Файл страницы не получен. Сайт можно открыть в браузере.';return end
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
        io.Fonts:AddFontFromFileTTF(font,16,nil,ranges)
        headingFont=io.Fonts:AddFontFromFileTTF(font,22,nil,ranges)
        titleFont=io.Fonts:AddFontFromFileTTF(font,38,nil,ranges)
    end
    if type(imgui.CreateTextureFromFile)=='function'and doesFileExist(artPath)then
        local ok,texture=pcall(imgui.CreateTextureFromFile,artPath)
        if ok and texture then artwork=texture else log('Фон недоступен; используется однотонная тема.')end
    end
    theme();initialized=true
end)
local function section(title,description)
    if headingFont then imgui.PushFont(headingFont)end
    imgui.Text(title)
    if headingFont then imgui.PopFont()end
    imgui.Spacing();imgui.TextColored(quiet,'SHVA / '..title:upper());imgui.Separator()
    imgui.TextWrapped(description);imgui.Spacing()
end
local function drawModule(m)
    section(m.title,m.desc)
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
    imgui.SameLine();imgui.TextDisabled('ArzHub '..m.version)
    local enabled=imgui.new.bool(cfg.enabled[m.id]~=false)
    if imgui.Checkbox('Включать при запуске##'..m.id,enabled) then
        cfg.enabled[m.id]=enabled[0];save()
        if enabled[0] and not live then defer(function()startModule(m)end)
        elseif not enabled[0] and live then feedback='Отключится после полного перезапуска игры. Игровые CEF-изменения нельзя надёжно снять выгрузкой Lua.' end
    end
    if not live and imgui.Button('Повторить загрузку') then defer(function()startModule(m)end) end
    if m.error then imgui.TextWrapped('Ошибка: '..m.error) end
    imgui.Spacing();imgui.TextWrapped(m.help);imgui.Spacing()
    for _,action in ipairs(m.actions) do
        if imgui.Button(action[1],imgui.ImVec2(260,35)) then local command=action[2];defer(function()runAction(m,command)end) end
    end
    imgui.Spacing();imgui.Separator();imgui.TextDisabled('Встроенные улучшения работают в исходных окнах игры.')
    imgui.TextWrapped('Окна истории и настроек этого модуля пока отдельные. Возврат в главное окно: '..keyName())
end

local function metric(label,value,width)
    imgui.BeginChild('##metric'..label,imgui.ImVec2(width,70),true,imgui.WindowFlags.NoScrollbar)
    imgui.TextColored(quiet,label)
    imgui.TextColored(accent,value)
    imgui.EndChild()
end
local function drawHome()
    drawHero(false)
    local n=0;for _,m in ipairs(modules)do if findModule(m)then n=n+1 end end
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
    imgui.Spacing();imgui.TextWrapped('Инвентарь, поиск и сортировка работают в игровых окнах. Истории и настройки отдельных модулей пока открываются отдельно.')
end
local function drawMarket()
    section('Поиск цен','Публичная база предложений MCR. Результаты открываются в браузере, а не считываются из всех лавок игрового клиента.')
    imgui.Text('Сервер: '..servers[cfg.server+1])
    imgui.PushItemWidth(360);imgui.InputTextWithHint('##item','Название товара',query,ffi.sizeof(query));imgui.PopItemWidth()
    if imgui.Button('Найти предложения',imgui.ImVec2(240,36))then local text=ffi.string(query);defer(function()browser(marketUrl(text))end)end
    if imgui.BeginCombo('Сервер',servers[cfg.server+1])then
        for i,name in ipairs(servers)do if imgui.Selectable(name,cfg.server==i-1)then cfg.server=i-1;save()end end
        imgui.EndCombo()
    end
    for _,pair in ipairs({{'Продажа','sell'},{'Скупка','buy'},{'Все','all'}})do if imgui.Button(pair[1])then cfg.mode=pair[2];save()end;imgui.SameLine()end
    imgui.NewLine();imgui.TextWrapped('Проверяй время обновления, валюту и наличие. Полнота базы зависит от сайта.')
end
local function drawSets()
    section('Конструктор сетов','Сохранённый сет Shadow Moon и конструктор ARZSET. Работа с сетом открывается в браузере; перенос вещей в игру не выполняется.')
    if imgui.Button('Открыть мой сет',imgui.ImVec2(260,36))then defer(function()browser(cfg.setUrl)end)end
    if imgui.Button('Собрать новый сет',imgui.ImVec2(260,36))then defer(function()browser('https://arzset.fun/')end)end
    if imgui.Button('Сохранить ссылку из буфера',imgui.ImVec2(260,36))then
        defer(function()
            if type(getClipboardText)~='function'then feedback='Буфер обмена недоступен.';return end
            local value=getClipboardText()
            if validSet(value)then cfg.setUrl=value;save();feedback='Ссылка сохранена.'else feedback='Скопируй полный адрес с https://arzset.fun/'end
        end)
    end
end

local function drawServers()
    section('Серверы и очереди','Онлайн и очередь по данным ArzHub. Обновление раз в минуту, пока открыт этот раздел.')
    if imgui.Button(monitor.busy and 'Загрузка...' or 'Обновить')then defer(refreshServers)end
    imgui.SameLine()
    if imgui.Button('Открыть сайт')then defer(function()browser('https://arzhub.top/servers')end)end
    if monitor.received>0 then
        local age=math.max(0,os.time()-monitor.received)
        imgui.TextColored(age>120 and accent or quiet,'Получено: '..os.date('%d.%m %H:%M:%S',monitor.received)..' ('..math.floor(age/60)..' мин. назад)')
        imgui.TextDisabled('Обновление у источника: '..monitor.sourceAge)
    else imgui.TextDisabled('Список ещё не загружен. При блокировке открой сайт кнопкой выше.')end
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
    imgui.Columns(1);imgui.Separator();imgui.TextDisabled('Источник: arzhub.top/servers. Это не твоя персональная позиция в очереди.')
end

local function openArzPriceTable()
    if type(sampIsChatCommandDefined)~='function'then
        feedback='Нельзя проверить локальную команду Arizona Market: нужен SAMPFUNCS.';say(feedback);return false
    end
    if not sampIsChatCommandDefined('crrxl')then
        feedback='Таблица недоступна: Arizona Market не запущен или ещё не зарегистрировал /crrxl.';say(feedback);return false
    end
    if type(sampProcessChatInput)~='function'then feedback='Не найден обработчик локальных команд.';say(feedback);return false end
    opened[0]=false
    sampProcessChatInput('/crrxl')
    feedback='Вызвана таблица Arizona Market. Доступ и данные проверяет исходный скрипт.'
    return true
end
local function registerArzAlias()
    if type(sampIsChatCommandDefined)=='function'and sampIsChatCommandDefined('crrhh')then
        say('/crrhh уже занята другим скриптом. Кнопка таблицы в меню остаётся доступной.');return false
    end
    sampRegisterChatCommand('crrhh',function()defer(openArzPriceTable)end)
    return true
end
local function drawArzTable()
    section('Таблица покупки и продажи','Открывает таблицу Arizona Market с заточкой, ценой покупки, ценой продажи, прибылью, датой обновления и графиками — как на твоём скриншоте.')
    local ready=type(sampIsChatCommandDefined)=='function'and sampIsChatCommandDefined('crrxl')
    imgui.TextColored(ready and imgui.ImVec4(0.40,0.87,0.65,1)or accent,ready and 'Локальная команда Arizona Market найдена' or 'Ожидание Arizona Market')
    imgui.Spacing()
    if imgui.Button('Открыть таблицу /crrhh',imgui.ImVec2(300,40))then defer(openArzPriceTable)end
    imgui.Spacing();imgui.TextWrapped('Новая команда SHVA_Helper: /crrhh. Команда /crrxl в Arizona Market сохраняется для совместимости.')
    imgui.Separator();imgui.TextWrapped('Это подключение существующего окна, не независимый перенос базы или графиков в SHVA_Helper. Arizona Market должен оставаться установленным. Подписка и разрешения, если они требуются таблицей, проверяются исходным скриптом.')
    imgui.TextWrapped('Без Arizona Market окно не откроется: приложение покажет причину и ничего не отправит в игровой чат.')
end

-- Updates use a publisher-controlled HTTPS manifest. No remote Lua is evaluated.
local releaseVersion='2.6.1-space-beta'
local defaultManifestUrl='https://raw.githubusercontent.com/xromxgame-lgtm/-/shva-updates/SHVA_Helper/manifest.json'
local updater={state='Ожидание проверки обновлений.',busy=false,available=false,seq=0,lastCheck=0}
local function readFile(path)
 local f=io.open(path,'rb');if not f then return nil end;local d=f:read('*a');f:close();return d
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
 updater.path=root..'/update-'..kind..'.tmp';os.remove(updater.path)
 local ok,err=pcall(downloadUrlToFile,url,updater.path,function(_,status)
  if updater.seq==seq and updater.busy and status==moonloader.download_status.STATUSEX_ENDDOWNLOAD then updater.done=true end
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
local function installUpdate()
 if not updater.available or updater.busy then return end
 updater.state='Загружаем '..updater.manifest.version..'…'
 beginUpdateDownload(updater.manifest.url,'script')
end
local function pollUpdates()
 if not updater.busy then return end
 if os.time()-updater.started>30 then updater.busy=false;updater.seq=updater.seq+1;updater.state='Сервер обновлений не ответил. Попробуй позже.';return end
 if not updater.done then return end
 updater.busy=false
 local data=readFile(updater.path);os.remove(updater.path)
 if not data or #data==0 or #data>2097152 then updater.state='Получен пустой или слишком большой файл.';return end
 if updater.kind=='manifest'then
  local ok,m=pcall(decodeJson,data)
  if not ok or type(m)~='table'or not versionParts(m.version)or type(m.sha256)~='string'or #m.sha256~=64 or m.sha256:find('[^%x]')or httpsOrigin(m.url)~=updater.origin then updater.state='Некорректный файл версии.';return end
  if not newer(m.version)then updater.state='Установлена актуальная версия: '..releaseVersion;return end
  updater.manifest=m;updater.available=true;updater.state='Доступна новая версия: '..m.version
  say('Доступно обновление '..m.version..'. Кнопка — в настройках SHVA_Helper.')
 else
  local ok,hash=pcall(sha256,data)
  if not ok or hash~=updater.manifest.sha256:lower()then updater.state='Проверка SHA-256 не пройдена. Скрипт не изменён.';return end
  if not loadstring(data,'SHVA_Helper update')then updater.state='В обновлении ошибка Lua. Скрипт не изменён.';return end
  local target=thisScript().path
  local old=readFile(target);if not old then updater.state='Не удалось прочитать текущий скрипт.';return end
  local function write(path,bytes)local f=io.open(path,'wb');if not f then return false end;local ok=f:write(bytes);local closed=f:close();return ok~=nil and closed~=nil end
  if not write(target..'.bak',old)or not write(target..'.new',data)then updater.state='Не удалось сохранить резервную копию или обновление.';return end
  local previous=target..'.previous';os.remove(previous)
  local moved=os.rename(target,previous)
  if not moved then updater.state='Не удалось заменить файл. Обновление отменено.';return end
  local installed=os.rename(target..'.new',target)
  if not installed then os.rename(previous,target);updater.state='Замена отменена; восстановлена предыдущая версия.';return end
  os.remove(previous);updater.available=false;updater.state='Обновление установлено. Перезапусти игру для применения.'
 end
end

local function drawSettings()
    imgui.TextColored(accent,'Обновления SHVA_Helper · '..releaseVersion)
    imgui.TextWrapped(updater.state)
    if imgui.Button('Проверить обновления')then defer(checkUpdates)end
    if updater.available and not updater.busy then imgui.SameLine();if imgui.Button('Обновить до '..updater.manifest.version)then defer(installUpdate)end end
    imgui.TextWrapped('Проверка при входе автоматическая. Установка — кнопкой, с резервной копией; применяется после перезапуска игры.')
    imgui.Separator()
    section('Настройки','Сочетание открытия можно изменить. F-клавиши не принимаются, чтобы не занимать управление игрой.')
    imgui.PushItemWidth(340)
    imgui.InputTextWithHint('##appName','Название приложения',appName,ffi.sizeof(appName))
    imgui.PopItemWidth()
    if imgui.Button('Сохранить название')then
        local name=ffi.string(appName):gsub('^%s+',''):gsub('%s+$',''):gsub('#','')
        if #name>0 and #name<80 and not name:find('[%c]')then cfg.name=name;save();feedback='Название сохранено.'else feedback='Название: от 1 до 79 байт, без управляющих символов.'end
    end
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
    imgui.Separator();imgui.TextWrapped('Авторы функциональных модулей: ArzHub. Единое окно и интеграция: SHVA_Helper. Исходники и версии указаны в SOURCES.txt.')
    imgui.TextWrapped('Старая база средних цен и настройки модулей не удаляются. Менеджер ArzHub не требуется для запуска этого комплекта.')
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
        imgui.TextColored(accent,'SHVA')
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
        navButton('Поиск цен',8);navButton('Мои сеты',9);navButton('Очереди серверов',11);navButton('Таблица /crrhh',12)
        imgui.Spacing();navButton('Настройки',10)
        imgui.EndChild();imgui.SameLine()
        imgui.BeginChild('##content',imgui.ImVec2(0,-32),false)
        if tab~=0 then drawHero(true);imgui.Spacing()end
        if tab==0 then drawHome()elseif tab<=7 then drawModule(modules[tab])elseif tab==8 then drawMarket()elseif tab==9 then drawSets()elseif tab==11 then drawServers()elseif tab==12 then drawArzTable()else drawSettings()end
        imgui.EndChild();imgui.Separator()
        imgui.TextColored(quiet,feedback~=''and feedback or(keyName()..'   /   Главное окно   /   2.6 SPACE BETA'))
    end
    imgui.End()
end)
function main()
    repeat wait(100)until isSampAvailable()
    if not doesDirectoryExist(root)then createDirectory(root)end
    load();save();loadServerCache();ffi.copy(appName,cfg.name);log('SHVA_Helper 2.6 Space startup');updateAccent();themeDirty=true
    checkUpdates()
    registerArzAlias()
    for _,m in ipairs(modules)do if cfg.enabled[m.id]~=false then startModule(m)end end
    say('Единое окно: '..keyName()..'. F7 не используется.')
    local last=false
    while true do
        wait(0)
        pollServers()
        pollUpdates()
        local pending=deferred;deferred={}
        for _,fn in ipairs(pending)do local ok,err=pcall(fn);if not ok then feedback='Ошибка действия: '..tostring(err);log(feedback)end end
        local busy=sampIsChatInputActive()or sampIsDialogActive()or isPauseMenuActive()
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
