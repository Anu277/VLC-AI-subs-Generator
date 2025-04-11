local check_interval = 5 -- seconds (used as a counter multiplier)
local max_attempts = 120 -- Maximum attempts (10 minutes at 5-second intervals)
local attempt = 0
local srt_loaded = false

function descriptor()
    return {
        title = "AGL Subs",
        version = "1.0",
        author = "Anurag Bheemani",
        shortdesc = "AGL Subs",
        description = "Auto-load matching .srt file from video folder after generating srt file. Keeps checking until the matching subtitle file is found and loaded. Displays video file path and name.",
        capabilities = { "input-listener" }
    }
end

function activate()
    vlc.msg.dbg("AGL Activated extension")
end

function deactivate()
    vlc.msg.dbg("AGL Deactivated extension")
end

function close()
    -- No cleanup needed without timer
end

function input_changed()
    attempt = 0
    srt_loaded = false
    check_srt() -- Check immediately on input change
end

function meta_changed()
    -- Dummy function to suppress warnings
    vlc.msg.dbg("[SUB-LOADER] Metadata changed (no action taken)")
end

function check_srt()
    if srt_loaded or not vlc.input.is_playing() then
        return
    end

    attempt = attempt + 1
    local item = vlc.input.item()
    if not item then
        vlc.msg.dbg("[SUB-LOADER] No input item found")
        return
    end

    local uri = item:uri() -- Get the URI of the current video
    vlc.msg.dbg("URI: " .. uri)
    local file_path = vlc.strings.decode_uri(uri):match("^file://(.+)$") or ""
    vlc.msg.dbg("File path: " .. file_path)
    
    -- Normalize path separators and convert to system-specific path
    file_path = file_path:gsub("\\", "/"):gsub("^/+", "")
    local file_name = file_path:match("([^/\\]+)$") or "Unknown"
    local base_path = file_path:match("(.+)%.%w+$") or file_path
    local srt_path = vlc.strings.encode_path(base_path .. ".srt")

    -- Display video file details
    vlc.msg.dbg("[SUB-LOADER] Current video URI: " .. uri)
    vlc.msg.dbg("[SUB-LOADER] Decoded file path: " .. file_path)
    vlc.msg.dbg("[SUB-LOADER] Video file name: " .. file_name)

    local file = io.open(srt_path, "r")
    if file then
        file:close()
        vlc.msg.dbg("[SUB-LOADER] Subtitle found, attempting to load: " .. srt_path)
        local success, err = pcall(function() vlc.input.add_subtitle(srt_path) end)
        if success then
            vlc.msg.dbg("[SUB-LOADER] Subtitle loaded successfully")
            srt_loaded = true
        else
            vlc.msg.err("[SUB-LOADER] Failed to load subtitle: " .. (err or "Unknown error"))
        end
    else
        vlc.msg.dbg("[SUB-LOADER] Waiting for: " .. srt_path)
    end

    if attempt < max_attempts and not srt_loaded then
        -- Schedule next check after a delay (approximated by VLC's event loop)
        vlc.misc.timer(function() check_srt() end, check_interval * 1000000)
    elseif attempt >= max_attempts then
        vlc.msg.dbg("[SUB-LOADER] Gave up looking for subtitle after " .. max_attempts .. " attempts.")
    end
end