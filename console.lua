local Native = require('lib.stdlib.native')
local Frame = require('lib.stdlib.oop.frame')
local Trigger = require('lib.stdlib.oop.trigger')
local Event = require('lib.stdlib.oop.event')
local Player = require('lib.stdlib.oop.player')

local OriginFrameType = require('lib.stdlib.enum.originframetype')
local FramePointType = require('lib.stdlib.enum.framepointtype')
local FrameEventType = require('lib.stdlib.enum.frameeventtype')
local OsKeyType = require('lib.stdlib.enum.oskeytype')

local Console = {}

function Console:init()
    print('|cff00ff00Console Loaded!!!|r press |cffff0000Alt+F1|r to toggle')

    self:initUi()
    self:initTrig()
    self:initHook()
    self.history = {}
    self.historyIndex = 0
end

function Console:initUi()
    if not Native.BlzLoadTOCFile([[UI\_console.toc]]) then
        print('|cffff0000Load console toc failed|r')
        return
    end

    local gameUi = Frame:getOrigin(OriginFrameType.GameUi, 0)

    local frameHash = 0

    self.console = Frame:create('__console', gameUi, 10, frameHash)
    if not self.console then
        print('|cffff0000Create console failed|r')
        return
    end

    self.console:hide()
    self.console:setPoint(FramePointType.Topleft, gameUi, FramePointType.Topleft, 0, 0)
    self.console:setPoint(FramePointType.Topright, gameUi, FramePointType.Topright, 0, 0)

    self.editBox = Frame:getByName('__consoleEditBox', frameHash)
    self.textArea = Frame:getByName('__consoleTextArea', frameHash)
end

function Console:initTrig()
    self.enterTrig = Trigger:create()
    self.enterTrig:registerFrameEvent(self.editBox, FrameEventType.EditboxEnter)
    self.enterTrig:addAction(function()
        local script = Event:getTriggerFrameText()
        if not script or script:trim() == '' then
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

function Console:initHook()
    if self.textArea then
        _G.print = function(...)
            local sb = {}
            for i = 1, select('#', ...) do
                sb[i] = tostring(select(i, ...))
            end
            self:addText(table.concat(sb, '    '))
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
        self.textArea:addText(text)
    end
end

function Console:toggle()
    self.console:setVisible(not self.console:isVisible())
end

Console:init()
