-- @classic@
require('bj')
local japi = require('jass.japi')
-- @classic-end@

require('stdlib.base')

local Native = require('stdlib.native')
local Frame = require('stdlib.oop.frame')
local Trigger = require('stdlib.oop.trigger')
local Event = require('stdlib.oop.event')
local Player = require('stdlib.oop.player')
local Message = require('stdlib.utils.message')

local OriginFrameType = require('stdlib.enum.originframetype')
local FramePointType = require('stdlib.enum.framepointtype')
local FrameEventType = require('stdlib.enum.frameeventtype')
local OsKeyType = require('stdlib.enum.oskeytype')

local Console = {}

function Console:init()
    Message:toAll('|cff00ff00Console Loaded!!!|r press |cffff0000Alt+F1|r to toggle')

    self:initUi()
    self:initTrig()
    self:initHook()
    self.history = {}
    self.historyIndex = 0
end

-- @reforge@
function Console:initUi()
    if not Native.BlzLoadTOCFile([[UI\_console.toc]]) then
        Message:toAll('|cffff0000Load console toc failed|r')
        return
    end

    local gameUi = Frame:getOrigin(OriginFrameType.GameUi, 0)

    local frameHash = 0

    self.console = Frame:create('__console', gameUi, 10, frameHash)
    if not self.console then
        Message:toAll('|cffff0000Create console failed|r')
        return
    end

    self.console:hide()
    self.console:setPoint(FramePointType.Topleft, gameUi, FramePointType.Topleft, 0, 0)
    self.console:setPoint(FramePointType.Topright, gameUi, FramePointType.Topright, 0, 0)

    self.editBox = Frame:getByName('__consoleEditBox', frameHash)
    self.textArea = Frame:getByName('__consoleTextArea', frameHash)
end
-- @end-reforge@

-- @reforge@
function Console:initTrig()
    self.enterTrig = Trigger:create()
    self.enterTrig:registerFrameEvent(self.editBox, FrameEventType.EditboxEnter)
    self.enterTrig:addAction(function()
        local script = Event:getTriggerFrameText()
        if not script or script:trim() == '' then
            return
        end

        if script == 'cls' then
            self.textArea:setText('')
            self.editBox:setText('')
            return
        end

        local f, err = load(script)
        if not f then
            self:addText(err)
            return
        end
        local ok, r = pcall(f)
        if not ok then
            self:addText(r)
            return
        end

        table.insert(self.history, 1, script)
        self.historyIndex = 0
        self.editBox:setFocus()
        self.editBox:setText('')
    end)

    self.showTrig = Trigger:create()
    self.showTrig:registerPlayerKeyEvent(Player:getLocal(), OsKeyType.F1, 4, true)
    self.showTrig:addAction(function()
        self:toggle()
    end)

    self.hideTrig = Trigger:create()
    self.hideTrig:registerPlayerKeyEvent(Player:getLocal(), OsKeyType.Escape, 0, true)
    self.hideTrig:addAction(function()
        self.console:hide()
    end)

    self.historyTrig = Trigger:create()
    self.historyTrig:registerFrameEvent(self.editBox, FrameEventType.MouseWheel)
    self.historyTrig:addAction(function()
        if not Event:getTriggerPlayer():isLocal() then
            return
        end
        if Event:getTriggerFrameValue() > 0 then
            if self.historyIndex < #self.history then
                self.historyIndex = self.historyIndex + 1
                self.editBox:setText(self.history[self.historyIndex])
            end
        elseif self.historyIndex > 1 and #self.history > 0 then
            self.historyIndex = self.historyIndex - 1
            self.editBox:setText(self.history[self.historyIndex])
        end
    end)
end
-- @end-reforge@

-- @classic@
function Console:initUi()
    local gameUi = japi.DzGetGameUI()
    local frameHash = 0

    japi.DzLoadToc([[UI\_console.toc]])

    self.console = japi.DzCreateFrame('__console', gameUi, frameHash)
    if not self.console then
        Message:toAll('|cffff0000Create console failed|r')
        return
    end

    japi.DzFrameSetPriority(self.console, 10)
    japi.DzFrameShow(self.console, false)
    japi.DzFrameSetPoint(self.console, FramePointType.Topleft, gameUi, FramePointType.Topleft, 0, 0)
    japi.DzFrameSetPoint(self.console, FramePointType.Topright, gameUi, FramePointType.Topright, 0, 0)

    self.editBox = japi.DzFrameFindByName('__consoleEditBox', frameHash)
    self.textArea = japi.DzFrameFindByName('__consoleTextArea', frameHash)
end
-- @end-classic@

-- @classic@
function Console:initTrig()
    local FrameEvents = {
        NONE = 0,
        FRAME_EVENT_PRESSED = 1,
        FRAME_MOUSE_ENTER = 2,
        FRAME_FOCUS_ENTER = 2,
        FRAME_MOUSE_LEAVE = 3,
        FRAME_FOCUS_LEAVE = 3,
        FRAME_MOUSE_UP = 4,
        FRAME_MOUSE_DOWN = 5,
        FRAME_MOUSE_WHEEL = 6,
        FRAME_CHECKBOX_CHECKED = 7,
        FRAME_CHECKBOX_UNCHECKED = 8,
        FRAME_EDITBOX_TEXT_CHANGED = 9,
        FRAME_POPUPMENU_ITEM_CHANGE_START = 10,
        FRAME_POPUPMENU_ITEM_CHANGED = 11,
        FRAME_MOUSE_DOUBLECLICK = 12,
        FRAME_SPRITE_ANIM_UPDATE = 13,
        FRAME_VALUE_CHANGED = 14,
        FRAME_EDITBOX_ENTER = 15,
    }

    local process = function()
        local script = japi.DzFrameGetText(self.editBox)
        if not script or script:trim() == '' then
            return
        end

        if script == 'cls' then
            japi.DzFrameSetText(self.textArea, '')
            japi.DzFrameSetText(self.editBox, '')
            return
        end

        local f, err = load(script)
        if not f then
            self:addText(err)
            return
        end
        local ok, r = pcall(f)
        if not ok then
            self:addText(r)
            return
        end

        table.insert(self.history, 1, script)
        self.historyIndex = 0
        japi.DzFrameSetText(self.editBox, '')
    end

    japi.DzFrameSetScriptByCode(self.editBox, FrameEvents.FRAME_EDITBOX_ENTER, process, false)

    japi.DzTriggerRegisterKeyEventByCode(nil, OsKeyType.Alt, 1, false, function()
        self.altKey = true
    end)
    japi.DzTriggerRegisterKeyEventByCode(nil, OsKeyType.Alt, 0, false, function()
        self.altKey = nil
    end)
    japi.DzTriggerRegisterKeyEventByCode(nil, OsKeyType.F1, 1, false, function()
        if self.altKey then
            self:toggle()
        end
    end)
    japi.DzTriggerRegisterKeyEventByCode(nil, OsKeyType.Escape, 1, false, function()
        japi.DzFrameShow(self.console, false)
    end)

    local function showHistory(up)
        if #self.history == 0 then
            return
        end
        if up then
            if self.historyIndex < #self.history then
                self.historyIndex = self.historyIndex + 1
            end
        else
            self.historyIndex = self.historyIndex - 1
        end
        japi.DzFrameSetText(self.editBox, self.history[self.historyIndex] or '')
        if self.historyIndex < 1 then
            self.historyIndex = 1
        end
    end
    japi.DzTriggerRegisterKeyEventByCode(nil, OsKeyType.Up, 1, false, function()
        showHistory(true)
    end)
    japi.DzTriggerRegisterKeyEventByCode(nil, OsKeyType.Down, 1, false, function()
        showHistory(false)
    end)
end
-- @end-classic@

function Console:initHook()
    if self.textArea then
        local orgPrint = print
        _G.print = function(...)
            local sb = {}
            for i = 1, select('#', ...) do
                sb[i] = tostring(select(i, ...))
            end
            self:addText(table.concat(sb, '    '))
            orgPrint(...)
        end

        if seterrorhandler then
            seterrorhandler(function(msg)
                self:addText('|cffff0000error: ' .. msg .. '|r')
            end)
        end
    end
end

---addText
---@param text string
---@return void
function Console:addText(text)
    if self.textArea then
        -- @classic@
        japi.DzFrameAddText(self.textArea, text)
        -- @end-classic@
        -- @reforge@
        self.textArea:addText(text)
        -- @end-reforge@
    end
end

function Console:toggle()
    -- @classic@
    japi.DzFrameShow(self.console, not japi.DzFrameIsVisible(self.console))
    -- @end-classic@
    -- @reforge@
    self.console:setVisible(not self.console:isVisible())
    -- @end-reforge@
end

Console:init()
