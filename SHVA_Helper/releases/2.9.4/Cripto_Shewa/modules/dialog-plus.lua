script_name('Dialog Plus')
script_author('ArzHub')
-- SHEVA_Helper integration: chat branding and violet/cyan visual theme; original authorship retained.
script_version('1.3.1')
script_url('https://arzhub.top/hub/dialog-plus')

-- Forum topic (current version, discussion): https://www.blast.hk/threads/256216/

local moonloader = require('moonloader') -- download_status for the update check.
local sampev = require('samp.events')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local function cp(s) return u8:decode(s) end

local tag = '{BB7AFF}[SHEVA_Helper]{FFFFFF}: '

local function notify(text)
    sampAddChatMessage(tag .. cp(text), -1)
end

local function readFile(path)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local content = f:read('*a')
    f:close()
    return content
end

local GRACE = 0.25 -- seconds after a dialog opens when digits are ignored: the key that opened it may still be held.

-- Swallow digits for the game while a list dialog is open.
local BLOCK_DIGITS = true
-- Digits the game binds to its own menus; an empty table means every digit.
local BLOCK_ONLY = { [2] = true, [3] = true }
local DEBUG = false -- log dialogs and keys to moonloader.log.

local function dbg(fmt, ...)
    if DEBUG then print(('[%7.2f] ' .. fmt):format(os.clock(), ...)) end
end

local LIST_STYLES = { [2] = true, [4] = true, [5] = true }  -- LIST / TABLIST / TABLIST_HEADERS
local INPUT_STYLES = { [1] = true, [3] = true }             -- INPUT / PASSWORD (have a text field)
local curStyle = nil
local shownAt = 0
local needBoot = false -- set by onShowDialog, the bootstrap is sent from the main loop.

local function isListDialog()
    return sampIsDialogActive() and LIST_STYLES[curStyle] == true
end

local function isInputDialog()
    return sampIsDialogActive() and INPUT_STYLES[curStyle] == true
end

local NUMKEYS = {} -- vkey -> digit (top row and numpad).
for i = 1, 9 do NUMKEYS[0x30 + i] = i; NUMKEYS[0x60 + i] = i end
NUMKEYS[0x30] = 10; NUMKEYS[0x60] = 10 -- 0 selects item 10.

-- Whether the game must not see this digit.
local function blocked(d)
    return d ~= nil and (next(BLOCK_ONLY) == nil or BLOCK_ONLY[d] == true)
end

-- A CEF dialog does not block game input, so a digit would also fire the game's bind; swallow it for the game only.
local WM_KEYDOWN, WM_KEYUP, WM_CHAR = 0x100, 0x101, 0x102

-- A keyup is swallowed only when its keydown was, otherwise the game sees the key as held forever.
local consumedDown = {} -- vkey -> true while a swallowed press is still held.

if BLOCK_DIGITS then
    -- List dialogs only, and not while chat or console input is open.
    addEventHandler('onWindowMessage', function(msg, wparam, lparam)
        if msg == WM_KEYUP then
            if consumedDown[wparam] then
                consumedDown[wparam] = nil
                consumeWindowMessage(true, false)
                dbg('hook: keyup vk=%02X swallowed', wparam)
            end
            return
        end
        -- Called for every window message, so filter by type first.
        if msg ~= WM_KEYDOWN and msg ~= WM_CHAR then return end
        if not isListDialog() or sampIsChatInputActive() or isSampfuncsConsoleActive() then return end
        if msg == WM_KEYDOWN and blocked(NUMKEYS[wparam]) then
            consumedDown[wparam] = true
            consumeWindowMessage(true, false)
            dbg('hook: keydown vk=%02X swallowed', wparam)
        elseif msg == WM_CHAR and wparam >= 0x30 and wparam <= 0x39 then
            -- WM_CHAR carries the character, not the vkey: '0' means digit 10, like NUMKEYS.
            if blocked(wparam == 0x30 and 10 or wparam - 0x30) then consumeWindowMessage(true, false) end
        end
    end)
end

-- Inject JS into the main CEF page (packet 220, sub-type 17).
local function evalcef(code)
    if type(code) ~= 'string' or code == '' or #code > 32767 then return false end
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt16(bs, #code)
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteString(bs, code)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
    return true
end

-- Page-side singleton: setMode keeps the dialog tweak applied via MutationObserver, press(N) picks item N.
-- Versioned: a live CEF context keeps the old code until script_version changes.
local BOOT_JS = ([==[
(function(){
    var VERSION='__VERSION__';
    var prev=window.__tmDialogPlus;
    if(prev){
        if(prev.version===VERSION)return;
        try{clearInterval(prev.iv);}catch(e){}
        try{if(prev.obs)prev.obs.disconnect();}catch(e){}
        window.__tmDialogPlus=null;
    }
    var ROW='.dialog-list-loop__list-item';
    var NUM_RE=/^\s*\[?(\d+)[\].]/;
    var STRIP_RE=/^\s*(?:\[[^\]]*\]|\d+[.)])\s*/;
    // Grey [N] prefix and data-tmnum on every selectable row: server numbers are kept, unnumbered lists are numbered by position.
    function numberRows(){
        var rows=document.querySelectorAll(ROW);
        if(!rows.length)return;
        var hasNums=false, parsed=[];
        for(var i=0;i<rows.length;i++){
            // Rows numbered by us do not count as server-numbered.
            var m=rows[i].getAttribute('data-tmauto')?null:(rows[i].textContent||'').match(NUM_RE);
            parsed[i]=m?parseInt(m[1],10):null;
            if(m)hasNums=true;
        }
        var auto=0;
        for(var i=0;i<rows.length;i++){
            var row=rows[i], num;
            if(parsed[i]!=null){ num=parsed[i]; }
            else if(!hasNums && (row.textContent||'').trim()!==''){ num=(++auto); row.setAttribute('data-tmauto','1'); }
            else { continue; }
            if(row.getAttribute('data-tmnum')===String(num) && row.querySelector('.tm-num')) continue;
            row.setAttribute('data-tmnum', num);
            var ns=document.createElement('span'); ns.className='tm-num'; ns.style.color='#C0C0C0'; ns.textContent='['+num+'] ';
            // Replace the leading marker in the first non-empty text node with our [N], so a server number is not doubled.
            var w=document.createTreeWalker(row, NodeFilter.SHOW_TEXT, null), tn=null, n;
            while(n=w.nextNode()){ if((n.nodeValue||'').trim()!==''){ tn=n; break; } }
            if(tn){
                var stripped=tn.nodeValue.replace(STRIP_RE,'');
                if(stripped!==tn.nodeValue) tn.nodeValue=stripped;
                tn.parentNode.insertBefore(ns, tn);
            }else{
                var host=row.querySelector('[data-column="1"]')||row;
                host.insertBefore(ns, host.firstChild);
            }
        }
    }
    // MAX on the layout indicator fills in the amount from the "Количество: N ед." line.
    function addMax(){
        var f=document.querySelector('.dialog-input__field');
        var desc=document.querySelector('.dialog-text__description');
        if(!f||!desc)return;
        var m=(desc.textContent||'').match(/\u041a\u043e\u043b\u0438\u0447\u0435\u0441\u0442\u0432\u043e:\s*([\d.\s]+)\u0435\u0434/);
        if(!m)return;
        var max=parseInt(m[1].replace(/[^\d]/g,''),10);
        if(!isFinite(max)||max<=0)return;
        var lang=document.querySelector('.dialog-input__keyboard-language');
        if(!lang)return;
        if(lang.textContent!=='MAX'){ lang.textContent='MAX'; lang.style.cursor='pointer'; lang.style.padding='0 8px'; }
        lang.onclick=function(){
            try{ var d=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value'); (d&&d.set?d.set:function(v){this.value=v;}).call(f,String(max)); }catch(e){ f.value=String(max); }
            f.dispatchEvent(new Event('input',{bubbles:true}));
            f.dispatchEvent(new Event('change',{bubbles:true}));
            f.focus();
        };
    }
    var mode=null, obs=null, pending=false;
    var OBS_OPTS={childList:true, subtree:true, characterData:true};
    // The observer is off while the tweak runs, or our own edits would re-trigger it.
    function kick(){
        var cur=window.__tmDialogPlus;
        if(!cur||cur.version!==VERSION||!mode)return;
        if(obs)obs.disconnect();
        try{ if(mode==='list')numberRows(); else if(mode==='input')addMax(); }
        catch(e){}
        finally{ if(obs&&mode)obs.observe(document.body, OBS_OPTS); }
    }
    function schedule(){
        if(pending)return;
        pending=true;
        setTimeout(function(){ pending=false; kick(); }, 30);
    }
    // 'list' | 'input' | null as seen by Lua; null stops the observer.
    function setMode(m){
        mode=m||null;
        if(!mode){ if(obs)obs.disconnect(); return; }
        kick();
    }
    // Select row D, or confirm it if it is already active.
    function press(D){
        if(mode==='list')numberRows();
        var rows=document.querySelectorAll(ROW);
        if(!rows.length)return;
        var el=null;
        for(var i=0;i<rows.length;i++){ if(rows[i].getAttribute('data-tmnum')==D){el=rows[i];break;} }
        if(!el){
            var numbered=false;
            for(var i=0;i<rows.length;i++){
                var m=(rows[i].textContent||'').match(NUM_RE);
                if(m){numbered=true; if(parseInt(m[1],10)===D){el=rows[i];break;}}
            }
            if(!el && !numbered && D-1<rows.length) el=rows[D-1];
        }
        if(!el)return;
        if(el.className.indexOf('dialog-list-loop__list-item--active')!==-1){
            var b=document.querySelector('.dialog__button--primary'); if(b)b.click();
        }else{
            el.click();
        }
    }
    obs=new MutationObserver(schedule);
    var iv=setInterval(kick, 1000);
    window.__tmDialogPlus={version:VERSION, obs:obs, iv:iv, kick:kick, setMode:setMode, press:press};
})();
]==]):gsub('__VERSION__', thisScript().version)

-- Bootstrap and mode in one call, so a recreated CEF context gets the singleton back on the next dialog.
local function sendMode(mode)
    evalcef(BOOT_JS .. ('window.__tmDialogPlus&&window.__tmDialogPlus.setMode(%s);'):format(
        mode and ("'" .. mode .. "'") or 'null'))
end

local function pressDigit(d)
    evalcef(('window.__tmDialogPlus&&window.__tmDialogPlus.press(%d);'):format(d))
end

-- ============================================================================
-- UPDATES (/dpupdate): only through the ArzHub manager, the script just says where to get them
-- ============================================================================

-- Update navigation belongs to the SHEVA_Helper host; no third-party manager downloads.
local function removeIfExists(path)return os.remove(path)end
local function checkForUpdate()
    if SHVA_HostOpenUpdates then SHVA_HostOpenUpdates()end
end
local function checkForUpdateSilently()end


function sampev.onShowDialog(id, style, title, button1, button2, text)
    curStyle = style
    needBoot = true -- no evalcef from inside the packet hook, the main loop sends it.
    shownAt = os.clock()
    dbg('dialog shown: id=%s style=%s title=%s', tostring(id), tostring(style), tostring(title))
end

function main()
    while not isSampAvailable() do wait(0) end
    -- Leftovers of an interrupted update by an older build; .old stays as the way back.
    removeIfExists(thisScript().path .. '.tmp')
    removeIfExists(thisScript().path .. '.manifest.tmp')
    wait(1500)

    if not SHVA_HostSilentStartup then notify('Загружен {73E6EF}v' .. thisScript().version .. '{FFFFFF}. В списках пункт выбирается цифрой, повторное нажатие подтверждает. В «Забрать» есть кнопка MAX.') end
    sampRegisterChatCommand('dpupdate', checkForUpdate)
    checkForUpdateSilently()

    local sentMode = false -- false = nothing sent yet, nil = no dialog.
    while true do
        wait(0)
        local mode = (isListDialog() and 'list') or (isInputDialog() and 'input') or nil
        if needBoot or mode ~= sentMode then
            needBoot = false
            sentMode = mode
            sendMode(mode)
            dbg('mode -> %s', tostring(mode))
        end
        -- Digits belong to the chat or console while their input is open.
        if mode == 'list' and not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
            for vk, d in pairs(NUMKEYS) do
                if isKeyJustPressed(vk) then
                    -- The digit that opened the dialog may still be held; counting it would confirm the remembered row.
                    if os.clock() - shownAt < GRACE then
                        dbg('digit %d ignored, dialog just opened', d)
                    else
                        dbg('digit %d pressed (vk=%02X)', d, vk)
                        pressDigit(d)
                    end
                end
            end
        end
    end
end
