-- Globals
last_heartbeat_time = 0
heartbeat_interval = 2000 -- 2 seconds
check_timer = nil

function descriptor()
    return {
        title = "ZestSync",
        version = "1.0",
        author = "Anurag Bheemani",
        shortdesc = "ZestSync Loader",
        description = "Auto-load matching .srt file from video folder.",
        capabilities = { "input-listener" }
    }
end


function activate()
    vlc.msg.dbg("ZestSync Extension Activated")

    local input = vlc.object.input()
    if not input then
        vlc.msg.warn("ZestSync No input object available")
        return
    end

    local item = vlc.input.item()
    if not item then
        vlc.msg.warn("ZestSync No input item found")
        return
    end

    local path = item:uri()
    path = vlc.strings.decode_uri(path):gsub("^file:///", ""):gsub("/", "\\")

    vlc.msg.dbg("ZestSync Loaded video from: " .. path)

    -- Replace any extension with .srt
    local srt_path = path:gsub("%.[^%.]+$", ".srt")

    vlc.msg.dbg("ZestSync Looking for subtitle: " .. srt_path)

    local success = vlc.input.add_subtitle(srt_path)

    if success then
        vlc.msg.dbg("ZestSync Subtitle added: " .. srt_path)
        vlc.osd.message("Subs loaded! To change, click 'V'", vlc.osd.channel_register(), "top-left", 3000000)


        -- Select last subtitle track
        vlc.delayed_callback(3000, function()
            set_last_subtitle()
        end)
    else
        vlc.msg.warn("ZestSync Could not load subtitle: " .. srt_path)
    end
end

function set_last_subtitle()
    local es = vlc.input.get_es()
    local last_sub_id = nil

    if es then
        for i, track in ipairs(es) do
            if track.type == "spu" then
                vlc.msg.dbg("ZestSync Found Subtitle Track ID: " .. tostring(track.id))
                last_sub_id = track.id
            end
        end

        if last_sub_id then
            vlc.var.set(vlc.object.input(), "spu", last_sub_id)
            vlc.msg.dbg("ZestSync Set subtitle track to ID: " .. tostring(last_sub_id))
        else
            vlc.msg.err("ZestSync No subtitle track found to activate.")
        end
    else
        vlc.msg.err("ZestSync No ES list found.")
    end
end
