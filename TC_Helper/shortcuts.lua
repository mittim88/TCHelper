local script_path = debug.getinfo(1, 'S').source:match([[^@?(.*[\/])[^\/]-$]])
package.path = script_path .. "?.lua;" .. package.path
local helper = require('helper')
local shortcuts = {}
local projectData = require('projectData')
function shortcuts.checkShortcuts()
    trackShortcuts = trackShortcuts or {}
    -- Verhindere das Erstellen von Events, wenn ein Shortcut zugewiesen wird
    if assigningShortcut then return end
    if textInputActive then return end
    -- Initialisiere globalShortcuts, falls sie nicht existiert
    globalShortcuts = globalShortcuts or { playPause = "P", createCue = "N" }
    -- Track-Shortcuts prüfen
    local usedTracks = projectData.readTrackGUID("used")
    for _, trackGUID in ipairs(usedTracks) do
        local assignedKey = trackShortcuts[trackGUID]
        if assignedKey then
            local imguiKeyFunc = reaper["ImGui_Key_" .. assignedKey]
            if imguiKeyFunc and reaper.ImGui_IsKeyPressed(ctx, imguiKeyFunc()) then
                -- Füge ein Cue zum Track hinzu, auch wenn kein Track ausgewählt ist
                addItem(trackGUID)
                return
            end
        end
    end
    -- Shortcut für Play/Pause
    if globalShortcuts.playPause then
        local playPauseKeyFunc = reaper["ImGui_Key_" .. globalShortcuts.playPause]
        if playPauseKeyFunc and reaper.ImGui_IsKeyPressed(ctx, playPauseKeyFunc()) then
            togglePlayPause()
        end
    end

    -- Shortcut für das Erstellen eines Cues im ausgewählten Track
    if globalShortcuts.createCue then
        local createCueKeyFunc = reaper["ImGui_Key_" .. globalShortcuts.createCue]
        if createCueKeyFunc and reaper.ImGui_IsKeyPressed(ctx, createCueKeyFunc()) then
            createCueInSelectedTrack()
        end
    end
end
function shortcuts.saveShortcuts()
    trackShortcuts = trackShortcuts or {}
    local serializedShortcuts = helper.tableToString(trackShortcuts)
    reaper.SetExtState("TCHelper", "TrackShortcuts", serializedShortcuts, true)
    reaper.SetExtState("TCHelper", "trackShortcutsSafed", "true", true)
end
function shortcuts.loadShortcuts()
    -- Initialisiere trackShortcuts, falls sie nicht existiert
    trackShortcuts = trackShortcuts or {}

    local serializedShortcuts = reaper.GetExtState("TCHelper", "TrackShortcuts")
    local userDefined = reaper.GetExtState("TCHelper", "trackShortcutsSafed")

    if serializedShortcuts and serializedShortcuts ~= "" and userDefined == "true" then
        -- Benutzer hat eigene Shortcuts gespeichert → lade diese
        trackShortcuts = helper.stringToTable(serializedShortcuts)
    else
        -- Noch keine eigenen Shortcuts gespeichert → Standard-Shortcuts 1-9 für die ersten 9 used Tracks
        local defaultKeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}
        local usedTracks = readTrackGUID("used")
        for i, trackGUID in ipairs(usedTracks) do
            if defaultKeys[i] then
                trackShortcuts[trackGUID] = defaultKeys[i]
            end
        end
        -- NICHT speichern! Erst speichern, wenn der User einen Shortcut selbst zuweist
    end
end
function shortcuts.initializeTrackShortcuts()
    trackShortcuts = trackShortcuts or {}
    -- Sicherstellen, dass trackShortcuts initialisiert ist
    --trackShortcuts = trackShortcuts or {}
    if trackShortcutsSafed == false or trackShortcutsSafed == 'false' then
        -- Hole die GUIDs der "used" Tracks
        local usedTracks = projectData.readTrackGUID("used")
        local defaultKeys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}
    
        -- Weisen Sie den ersten 9 "used" Tracks die Shortcuts 1-9 zu
        for i = 1, math.min(#usedTracks, 9) do
            local trackGUID = usedTracks[i]
            trackShortcuts[trackGUID] = defaultKeys[i]
            consoleMSG('TrackGUID: '..trackGUID..' assigned to: '..defaultKeys[i])
        end
        -- Optional: Shortcuts speichern
        shortcuts.saveShortcuts()
        
    end
end
function shortcuts.saveGlobalShortcuts()
    local serializedShortcuts = helper.tableToString(globalShortcuts)
    reaper.SetExtState("TCHelper", "GlobalShortcuts", serializedShortcuts, true)
    reaper.SetExtState("TCHelper", "globalShortcutsSafed", "true", true)
end
function shortcuts.loadGlobalShortcuts()
    -- Initialisiere globalShortcuts, falls sie nicht existiert
    if not globalShortcuts then
        globalShortcuts = { playPause = "Space", createCue = "." }
    end

    local serializedShortcuts = reaper.GetExtState("TCHelper", "GlobalShortcuts")
    if serializedShortcuts and serializedShortcuts ~= "" then
        globalShortcuts = helper.stringToTable(serializedShortcuts)
    else
        -- Standard-Shortcuts definieren, wenn keine vorhanden sind
        globalShortcuts = { playPause = "Space", createCue = "." }
        shortcuts.saveGlobalShortcuts() -- Speichere die Standard-Shortcuts
    end
end















return shortcuts