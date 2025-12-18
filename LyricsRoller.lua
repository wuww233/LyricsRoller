--[[
    同一时间的字幕 按照原本的顺序从上到下显示
    支持卡拉OK，但是需要把强调的字体颜色设为主要颜色
    支持自动换行 但是英文单词会被拆开
    建议在最后一行字幕后增加一行持续到视频结束的空行、在第一行前加一行从头开始的
    自动换行时会检测行内的{} 但不会检测括号不匹配的错误 请自行确保语法正确；并且计算宽度时不会考虑行内字体的变化
    tag-lL cC rR 可以手动指定某一行的对齐方式 
]]

script_name = "LyricsRoller - 歌词滚动生成器"
script_description = "把带有时间轴的多行字幕转换为类似音乐软件中歌词滚动的效果";
script_author = "Jungezi";
script_version = "1.2.1";
script_last_update_date = "2025/02/27";

include("karaskel.lua")
include("unicode.lua")

config_file = "LyricsRoller_config.txt"

all_macros = {
	{
		script_name = "复原",
		script_description = "删除指定特效名生成的效果(包括行和样式)\n并取消原行的注释",
		entry = function(subs,sel) recover(subs, sel) end,
		validation = false
	},
	{
		script_name = "生成",
        script_description = "注释指定特效名的行 并生成效果",
		entry = function(subs,sel) generate(subs, sel) end,
		validation = false
	},
}

recover_config=
{
    
	{class="label",x=0,y=0,label="特效名"},
	{class="edit",name="tag",x=1,y=0,value="tag", hint="原行的特效名\n即不包含-roller的特效名"},
}

generate_config=
{
	{class="label",x=0,y=0,label="特效名"},
	{class="edit",name="tag",x=2,y=0,value="tag"},


	{class="label",x=0,y=1,label="显示范围"},

	{class="label",x=1,y=1,label="左上(x,y)"},
	{class="intedit",name="bound_1x",x=2,y=1,value=0},
	{class="intedit",name="bound_1y",x=3,y=1,value=0},

	{class="label",x=1,y=2,label="右下(x,y)"},
	{class="intedit",name="bound_2x",x=2,y=2},
	{class="intedit",name="bound_2y",x=3,y=2},


	{class="label",x=0,y=4,label="更多参数 >"},


	{class="label",x=0,y=5,label="强调组"},

	{class="label",x=1,y=5,label="字体颜色"},
	{class="dropdown",name="color",x=2,y=5,items={"主要颜色","次要颜色"},value="主要颜色", hint="强调组使用样式中的主要颜色or次要颜色\n(改变样式中的字体颜色后需要重新生成才能应用颜色的修改)"},

	{class="label",x=1,y=6,label="位置比例(%)"},
	{class="intedit",name="position",x=2,y=6,value=30, hint="强调组行顶的位置 相对于整个显示范围\n(最上面是0 最下面是1)", min=0,max=100},

	{class="label",x=1,y=7,label="缩放(%)"},
	{class="intedit",name="scale",x=2,y=7,value=100,min=0},

	{class="label",x=1,y=8,label="动画时长(毫秒)"},
	{class="intedit",name="times",x=2,y=8,value=100,min=0, hint="从普通行变为强调组 或强调组变回普通行 所用动画的时长\n包括缩放和透明度变化"},
    

	{class="label",x=0,y=9,label="普通组"},

	{class="label",x=1,y=9,label="字体颜色"},
	{class="dropdown",name="color_norm",x=2,y=9,items={"主要颜色","次要颜色"},value="主要颜色", hint="普通组使用样式中的主要颜色or次要颜色\n(改变样式中的字体颜色后需要重新生成才能应用颜色的修改)"},

	{class="label",x=1,y=10,label="不透明度(%)"},
	{class="intedit",name="opacity",x=2,y=10,value=60,min=0,max=100},

	{class="label",x=0,y=11,label="组间距"},
	{class="intedit",name="spacing",x=2,y=11,value=40,min=0},
    
	{class="label",x=0,y=12,label="组内间距"},
	{class="intedit",name="spacing_inner",x=2,y=12,value=5,min=0},

	{class="label",x=0,y=13,label="默认字幕对齐"},
	{class="dropdown",name="align",x=2,y=13,items={"左对齐","中间对齐","右对齐"},value="中间对齐", hint="在指定特效名后加入以下后缀可对此行设置特定对齐方式\n-l左对齐 -c中间对齐 -r右对齐"},
	
    {class="label",x=0,y=14,label="淡入时长(毫秒)"},
	{class="intedit",name="fade_in",x=2,y=14,value=0,min=0, hint="淡入显示滚动歌词的动画时长"},
    {class="label",x=0,y=15,label="淡出时长(毫秒)"},
	{class="intedit",name="fade_out",x=2,y=15,value=0,min=0, hint="淡出显示滚动歌词的动画时长"},

    {class="checkbox",name="edge_fade",x=0,y=16,width=4,label="首末组字幕透明度渐变", hint="显示范围内的第一组和最后一组字幕会有透明度渐变效果\n取消后只做硬裁剪",value=true},
    {class="checkbox",name="karaok",x=0,y=17,width=4,label="卡拉OK模式型字体颜色", hint="勾选此选项会覆盖字体颜色的设置为以下颜色：\n强调组为次要颜色转主要颜色\n强调组上方普通组使用主要颜色 下方普通组使用次要颜色\n(改变样式中的字体颜色后需要重新生成才能应用颜色的修改)",value=false},
    {class="checkbox",name="save_config",x=0,y=18,width=4,label="记忆本次输入的参数", hint="会生成文件 LyricsRoller_config.txt",value=false},

}

function cal_group_position(base_y, current_group, group_size_height, group_size_height_scale, configs, is_scale)  -- 计算所有组的位置
    
    local first_y = base_y
    for i = 1, current_group - 1 do
        first_y = first_y - group_size_height[i] - configs.spacing    -- 计算第一组字幕的位置
    end
    local group_positon_y = {first_y}
    for i = 2, current_group do
        group_positon_y[i] = group_positon_y[i-1] + group_size_height[i-1] + configs.spacing  -- 强调前的字幕
    end

    if current_group == 0 then  -- 开始阶段
        group_positon_y[1] = base_y
    elseif current_group < #group_size_height then
        if is_scale then
            group_positon_y[current_group + 1] = base_y + group_size_height_scale[current_group] + configs.spacing    -- 强调后的第一个字幕
        else
            group_positon_y[current_group + 1] = base_y + group_size_height[current_group] + configs.spacing    -- 强调后的第一个字幕 不缩放
        end
    end
    for i = current_group + 2, #group_size_height do
        group_positon_y[i] = group_positon_y[i-1] + group_size_height[i-1] + configs.spacing
    end

    return group_positon_y

end

function line_add_effect(line, effect)   -- 为行添加特定的特效，若已有该标签则修改，否则增加
    if line.text:find("^{.*}") then -- 以{}开头
        line.text = line.text:gsub("}", effect .. "}",1) -- 修改已有字体大小标签
    elseif effect ~= "" then
        line.text = "{" .. effect .. "}" .. line.text -- 添加字体大小标签
    end
    return line
end

function percent_to_hex(opacity)    -- 把百分比0-100的值按比例转为十六进制00-FF
    if opacity < 0 then opacity = 0 end
    if opacity > 100 then opacity = 100 end
    return string.format("%02X",(100-opacity) * 255 / 100)
end

function line_fade_out(line, y_start, y_end, bound, position_y, opacity, is_up, enable_fade) -- 把一行字幕从y_start到y_end的不透明度从1渐变为0
    local parts = 10    -- 渐变10次
    local lines = {}
    if not enable_fade then
        -- aegisub.log(3,"不执行渐变\n")
        local clipped_line = util.deep_copy(line)
        clipped_line = line_add_effect(clipped_line, "\\clip(" .. bound[1][1] .. "," .. bound[1][2] .. "," .. bound[2][1] .. "," .. bound[2][2] .. ")")
        lines[1] = clipped_line
        return lines
    end

    if math.abs(y_end - y_start) < 0.001 then
        local clipped_line = util.deep_copy(line)
        clipped_line = line_add_effect(clipped_line, "\\clip(" .. bound[1][1] .. "," .. bound[1][2] .. "," .. bound[2][1] .. "," .. bound[2][2] .. ")")
        lines[1] = clipped_line
        return lines
    end

    local total_steps = math.max(parts,1)
    local y_step = (y_end-y_start)/(parts+1)  -- 11次变化才能渐变10次
    local function eased_opacity(step_index)
        if step_index < 1 then step_index = 1 end
        local t = (step_index - 1) / total_steps
        if t > 1 then t = 1 end
        local eased = math.cos(t * math.pi / 2)
        if eased < 0 then eased = 0 end
        return opacity * eased
    end
    local step_index = 0

    if is_up then      -- 上方渐变
        
        for y = y_start, y_end, y_step do
            local this_line = util.deep_copy(line)
            step_index = step_index + 1

            local y_bound = y
            if y == y_start then y_bound = bound[2][2] end  -- 最下方的一个clip

            local fade_opacity = eased_opacity(step_index)
            this_line = line_add_effect(this_line, "\\clip(" .. bound[1][1] .. "," .. y+y_step .. "," .. bound[2][1] .. "," .. y_bound .. ")\\alpha&" .. percent_to_hex(fade_opacity) .. "&")
            
            lines[#lines + 1] = this_line
        end
    else -- 下方渐变 
        for y = y_start, y_end, y_step do
            local this_line = util.deep_copy(line)
            step_index = step_index + 1

            local y_bound = y
            if y == y_start then y_bound = bound[1][2] end  -- 最上方的一个clip

            local fade_opacity = eased_opacity(step_index)
            this_line = line_add_effect(this_line, "\\clip(" .. bound[1][1] .. "," .. y_bound .. "," .. bound[2][1] .. "," .. y+y_step .. ")\\alpha&" .. percent_to_hex(fade_opacity) .. "&")

            lines[#lines + 1] = this_line
        end
    end

    return lines
end

function clear_effect(text)
    return text:gsub("{.-}","") -- 去除所有{}
end

-- 计算在scale缩放下的行高、且自动换行
function deal_with_size(line, max_width, scale)
    local width, height = aegisub.text_extents(line.styleref, clear_effect(line.text))

    local new_text = ""
    width = width * scale / 100
    if width > max_width then   -- 超过一行

        local new_line = ""
        local text_line = 0 -- 行数
        local in_brace = false
        local in_brace_string = ""
        for char in unicode.chars(line.text) do -- 遍历每一个字符
            if char == "{" then
                in_brace = true 
                in_brace_string = in_brace_string .. char
            elseif char == "}" then 
                in_brace_string = in_brace_string .. char
                in_brace = false 
            else
                if in_brace == true then -- 特效内
                    in_brace_string = in_brace_string .. char
                else
                    local new_line_temp = new_line .. char
                    width = aegisub.text_extents(line.styleref, clear_effect(new_line_temp))
                    width = width * scale / 100
                    if width>max_width then -- 超出一行
                        if text_line == 0 then
                            new_text = new_line
                        else
                            new_text = new_text .. "\\N" .. new_line
                        end
                        text_line = text_line + 1
                        new_line = in_brace_string .. char -- 进入新的一行，且特效放在换行符后
                        in_brace_string = ""
                    else  -- 仍在这一行
                        new_line = new_line .. in_brace_string .. char  -- 加入特效
                        in_brace_string = ""   -- 清空特效
                    end
                end
            end
        end
        if new_line ~= nil then
            new_text = new_text.."\\N".. new_line    -- 最后一行
            text_line = text_line+1
        end
        
        width, height = aegisub.text_extents(line.styleref, clear_effect(new_text))
        height = text_line * height
    else
        new_text = line.text
    end
    height = height * scale / 100
    return height,new_text
    
end

function deal_with_time(styles, roller_lines, configs, bound, font_opacity)
    local group_end_time = {}
    local group_start_time = {}
    local group_cnt = 1
    local end_time_max = roller_lines[1].end_time
    local group_index = {1}      -- group_index[i] 为第i行对应的组号
    local line_height = {}
    local line_height_scale = {}
    local line_text = {}
    local line_text_scale = {}


    for i=1,#roller_lines do    -- 拆分行到适应宽度 并计算行高
        line_height[i],line_text[i] = deal_with_size(roller_lines[i], bound[2][1]-bound[1][1], 100)
        line_height_scale[i],line_text_scale[i] = deal_with_size(roller_lines[i], bound[2][1]-bound[1][1], configs.scale)
    end

    local current_group_height = line_height[1]
    local current_group_height_scale = line_height_scale[1]
    local group_bias = {0, current_group_height + configs.spacing_inner} -- 第i行在组内的y偏移
    local group_bias_scale = {0, current_group_height_scale + configs.spacing_inner * configs.scale / 100} -- 第i行在组内的y偏移

    local group_size_height = {}
    local group_size_height_scale = {}
    for i = 2, #roller_lines do -- 计算组内偏移 和 组的开始结束时间

        local line = roller_lines[i]
        local height = line_height[i]
        local height_scale = line_height_scale[i]

        if roller_lines[i-1].start_time ~= line.start_time then             -- 新的一组
            group_size_height[group_cnt] = current_group_height
            group_size_height_scale[group_cnt] = current_group_height_scale
            group_end_time[group_cnt] = math.min(end_time_max, line.start_time)  -- 组的结束时间要早于下一组的开始时间 
            group_start_time[group_cnt] = roller_lines[i-1].start_time
            
            group_cnt = group_cnt + 1
            end_time_max = 0
            current_group_height = 0
            current_group_height_scale = 0

            group_bias[i] = 0
            group_bias[i + 1] = height + configs.spacing_inner
            group_bias_scale[i] = 0
            group_bias_scale[i + 1] = height_scale + configs.spacing_inner * configs.scale / 100
        else
            group_bias[i + 1] = group_bias[i] + height + configs.spacing_inner
            group_bias_scale[i + 1] = group_bias_scale[i] + height_scale + configs.spacing_inner * configs.scale / 100
        end

        group_index[i] = group_cnt
        end_time_max = math.max(line.end_time, end_time_max)
        current_group_height = current_group_height + height
        current_group_height_scale = current_group_height_scale + height_scale

    end
    group_size_height[group_cnt] = current_group_height
    group_size_height_scale[group_cnt] = current_group_height_scale
    group_end_time[group_cnt] = end_time_max
    group_start_time[group_cnt] = roller_lines[#roller_lines].start_time

    -- 统一同一组的结束时间
    for i = 1, #roller_lines do
        local line_previous = roller_lines[i]
        line_previous.end_time = group_end_time[group_index[i]]
        roller_lines[i] = line_previous
    end

    -- 将间隔小于动画时间的两组的 结束时间 和 开始时间 对齐
    for i = 1, group_cnt-1 do
        if group_end_time[i] ~= group_start_time[i+1] and group_end_time[i] + configs.times >= group_start_time[i+1] then
            group_end_time[i] = group_start_time[i+1]
        end
    end


    -- \a5-7 左中右 上对齐  \a9-11 左中右 中对齐
    local position_str = {"\\a5","\\a6","\\a7"}
    local position_x = {bound[1][1],(bound[1][1]+bound[2][1])/2, bound[2][1]}
    local position_y = (bound[2][2] - bound[1][2])*configs.position / 100 + bound[1][2]

    local opacity_hex = percent_to_hex(configs.opacity)

    -- 初始位置
    local last_y = {0}
    local group_positon_y_init = cal_group_position(position_y, 0, group_size_height, group_size_height_scale, configs, true)
    for i = 1, #roller_lines do 
        last_y[i] = group_positon_y_init[group_index[i]] + group_bias[i]
    end

    local subtitles_generate = {}
    local last_time = 0
    group_start_time[group_cnt+1] = group_end_time[group_cnt]

    local norm_color_pre_is1
    local norm_color_ftr_is1
    local emphasize_color_is1

    if configs.karaok == true then
        norm_color_pre_is1 = true
        norm_color_ftr_is1 = false
        emphasize_color_is1 = true
    else
        if configs.color_norm == "主要颜色" then
            norm_color_pre_is1 = true
            norm_color_ftr_is1 = true
        else
            norm_color_pre_is1 = false
            norm_color_ftr_is1 = false
        end

        if configs.color == "主要颜色" then -- 变色
            emphasize_color_is1 = true
        else
            emphasize_color_is1 = false
        end
    end

    -- 过程模拟：开始滚动
    for current_group = 1, group_cnt do   -- current_group: 当前强调显示的行
        local group_positon_y = cal_group_position(position_y, current_group, group_size_height, group_size_height_scale, configs, true)

        for i = 1, #roller_lines do 
            local line = util.deep_copy(roller_lines[i])
            local y = group_positon_y[group_index[i]]

            local norm_color_pre
            local norm_color_ftr
            local emphasize_color
            if norm_color_pre_is1 then norm_color_pre = styles[line.style].color1 else norm_color_pre = styles[line.style].color2 end
            if norm_color_ftr_is1 then norm_color_ftr = styles[line.style].color1 else norm_color_ftr = styles[line.style].color2 end
            if emphasize_color_is1 then emphasize_color = styles[line.style].color1 else emphasize_color = styles[line.style].color2 end


            if group_index[i] == current_group then     -- 普通组变为强调组
                line.text = line_text_scale[i]
                y = y + group_bias_scale[i] -- 计算组内偏移距离
                line = line_add_effect(line, "\\c" .. norm_color_ftr .. "\\fsc100\\alpha&" .. opacity_hex .. "&\\t(" .. 0 .. "," .. configs.times .. ",\\c" .. emphasize_color .. "\\fsc" .. configs.scale .. "\\alpha&00" .. "&)")   -- 变不透明
            else    -- 普通组
                line.text = line_text[i]
                y = y + group_bias[i]
                line.text = line.text:gsub("\\[kK][of]?[0-9]*", "") -- 去除非强调行的卡拉OK效果
                line.text = line.text:gsub("{}", "") -- 去除非强调行的空特效
                

                if group_index[i] == current_group - 1 and group_end_time[current_group-1] == group_start_time[current_group] then -- 强调组变为普通组
                    line = line_add_effect(line, "\\fsc" .. configs.scale .. "\\c" .. emphasize_color  .. "\\t(" .. 0 .. "," .. configs.times .. "," .. "\\c" .. norm_color_pre .. "\\fsc100\\alpha&" .. opacity_hex .. "&)")
                else
                    line = line_add_effect(line, "\\alpha&" .. opacity_hex .. "&")
                    if group_index[i] < current_group then
                        line = line_add_effect(line, "\\c" .. norm_color_pre)
                    else
                        line = line_add_effect(line, "\\c" .. norm_color_ftr)
                    end
                end

                -- line = line_add_effect(line, "\\t(0,".. configs.times .. ",\\alpha&" .. opacity_hex .. "&)")    -- 变透明
            end

            line = line_add_effect(line, position_str[line.align])
            line.start_time = group_start_time[current_group]
            line.end_time = group_end_time[current_group]

            -- 移动到对应位置
            line = line_add_effect(line,"\\move(" .. position_x[line.align] .. "," .. last_y[i] .. "," .. position_x[line.align] .. "," .. y .. "," .. 0 .. "," .. configs.times .. ")")
            if current_group == 1 then
                line = line_add_effect(line,"\\fade(" .. configs.fade_in ..",0)")
            elseif current_group == group_cnt then
                line = line_add_effect(line,"\\fade(0," .. configs.fade_out ..")")
            end

            -- 在显示范围内 或者 从显示范围内进入/离开
            if (y <= bound[2][2] and y + line_height_scale[i] >= bound[1][2]) or (last_y[i] <= bound[2][2] and last_y[i] + line_height_scale[i] >= bound[1][2]) then 

                local lines={}
              
                if y + line_height_scale[i] >= bound[2][2] then    -- 下方
                    if y <= bound[2][2] then
                        lines = line_fade_out(line, y, bound[2][2], bound, position_x[line.align], configs.opacity,false, edge_fade_enabled)
                    else
                        lines = line_fade_out(line, last_y[i], bound[2][2], bound, position_x[line.align], configs.opacity,false, edge_fade_enabled)
                    end
                elseif y <= bound[1][2] then -- 上方
                    if y + line_height_scale[i] >= bound[1][2] then
                        lines = line_fade_out(line, y+line_height_scale[i], bound[1][2], bound, position_x[line.align], configs.opacity,true, edge_fade_enabled)
                    else
                        lines = line_fade_out(line, last_y[i]+line_height_scale[i], bound[1][2], bound, position_x[line.align], configs.opacity,true, edge_fade_enabled)
                    end
                else --内部
                    line = line_add_effect(line, "\\clip(" .. bound[1][1] .. "," .. bound[1][2] .. "," .. bound[2][1] .. "," .. bound[2][2] .. ")")
                    lines[1] = line
                end

                for i, single_line in ipairs(lines) do
                    table.insert(subtitles_generate, single_line)
                end 
            end

            last_y[i] = y
        end

        -- 强调组结束后 下一组强调前的时间段
        if group_end_time[current_group] ~= group_start_time[current_group+1] then
            
            local group_positon_y = cal_group_position(position_y, current_group, group_size_height, group_size_height_scale, configs, false)


            for i = 1, #roller_lines do 
                local line = util.deep_copy(roller_lines[i])
                local y = group_positon_y[group_index[i]]

                local norm_color_pre
                local norm_color_ftr
                local emphasize_color
                if norm_color_pre_is1 then norm_color_pre = styles[line.style].color1 else norm_color_pre = styles[line.style].color2 end
                if norm_color_ftr_is1 then norm_color_ftr = styles[line.style].color1 else norm_color_ftr = styles[line.style].color2 end
                if emphasize_color_is1 then emphasize_color = styles[line.style].color1 else emphasize_color = styles[line.style].color2 end
    

                if group_index[i] == current_group then     -- 强调组变回普通组
                    line.text = line_text[i]
                    y = y + group_bias[i] -- 计算组内偏移距离
                    line = line_add_effect(line, "\\fsc" .. configs.scale .. "\\c" .. emphasize_color  .. "\\t(" .. 0 .. "," .. configs.times .. "," .. "\\c" .. norm_color_pre .. "\\fsc100\\alpha&" .. opacity_hex .. "&)")
                
                else    -- 普通组
                    line.text = line_text[i]
                    y = y + group_bias[i]
                    line = line_add_effect(line, "\\alpha&" .. opacity_hex .. "&")
                    if group_index[i] < current_group then
                        line = line_add_effect(line, "\\c" .. norm_color_pre)
                    else
                        line = line_add_effect(line, "\\c" .. norm_color_ftr)
                    end
                end
                

                line.text = line.text:gsub("\\[kK][of]?[0-9]*", "") -- 去除卡拉OK效果
                line.text = line.text:gsub("{}", "") -- 去除空特效

                line = line_add_effect(line, position_str[line.align])
                line.start_time = group_end_time[current_group]
                line.end_time = group_start_time[current_group+1]

                -- 移动到对应位置
                line = line_add_effect(line,"\\move(" .. position_x[line.align] .. "," .. last_y[i] .. "," .. position_x[line.align] .. "," .. y .. "," .. 0 .. "," .. configs.times .. ")")

                -- 在显示范围内 或者 从显示范围内进入/离开
                if (y <= bound[2][2] and y + line_height[i] >= bound[1][2]) or (last_y[i] <= bound[2][2] and last_y[i] + line_height[i] >= bound[1][2]) then 

                    local lines={}
                
                    if y + line_height[i] >= bound[2][2] then    -- 下方
                        if y <= bound[2][2] then
                        lines = line_fade_out(line, y, bound[2][2], bound, position_x[line.align], configs.opacity,false, edge_fade_enabled)
                    else
                        lines = line_fade_out(line, last_y[i], bound[2][2], bound, position_x[line.align], configs.opacity,false, edge_fade_enabled)
                    end
                elseif y <= bound[1][2] then -- 上方
                    if y + line_height[i] >= bound[1][2] then
                        lines = line_fade_out(line, y+line_height[i], bound[1][2], bound, position_x[line.align], configs.opacity,true, edge_fade_enabled)
                    else
                        lines = line_fade_out(line, last_y[i]+line_height[i], bound[1][2], bound, position_x[line.align], configs.opacity,true, edge_fade_enabled)
                    end
                    else --内部
                        line = line_add_effect(line, "\\clip(" .. bound[1][1] .. "," .. bound[1][2] .. "," .. bound[2][1] .. "," .. bound[2][2] .. ")")
                        lines[1] = line
                    end

                    for i, single_line in ipairs(lines) do
                        table.insert(subtitles_generate, single_line)
                    end 
                end

                last_y[i] = y
            end
        end

        last_time = group_end_time[current_group]
        
    end

    return subtitles_generate
end


function lyrics_roller(subtitles, configs)
    -- 设置指定的特效字符串
    local target_effect = configs.tag
    local bound = {
        {configs.bound_1x,configs.bound_1y},
        {configs.bound_2x,configs.bound_2y}
    }
    -- 是否启用边缘渐变
    local edge_fade_enabled = configs.edge_fade
    -- 存储满足条件的行
    local roller_lines = {}
    local new_styles = {}

    -- 初始化 meta 和 styles
    local meta, styles = karaskel.collect_head(subtitles)

    -- 获取加载视频的尺寸
    local xres, yres = aegisub.video_size()

    local style_used = {}
    local len = #subtitles
    -- 遍历字幕文件中的每一行
    for i = 1, len do
        local line = subtitles[i]

        -- 删除之前增加的字幕
        -- while line.class == "dialogue" and line.effect == target_effect .. "-roller" or line.class == "style" and line.name:find("_" .. target_effect .."%-roller$") do
        while line.class == "dialogue" and line.effect:find("^" .. target_effect ..".*%-roller$") do
            subtitles.delete(i)
            len = len - 1
            if i == len + 1 then
                break
            end
            line = subtitles[i]
        end
        if i == len + 1 then
            break
        end


        -- if line.class == "dialogue" and line.effect == target_effect then   -- 即使注释了也会执行操作
        if line.class == "dialogue" and (line.effect == target_effect or line.effect:find("^" .. target_effect .."%-[LCRlcr]$")) then   -- tag / tag-l / tag-c / tag-r
            -- 解析行样式信息
            karaskel.preproc_line(subtitles, meta, styles, line)


            if line.effect:find("^" .. target_effect .."%-[Ll]$") then
                line.align = 1
            elseif line.effect:find("^" .. target_effect .."%-[Cc]$") then
                line.align = 2
            elseif line.effect:find("^" .. target_effect .."%-[Rr]$") then
                line.align = 3
            else
                if configs.align == "左对齐" then
                    line.align = 1
                elseif configs.align == "中间对齐" then
                    line.align = 2
                elseif configs.align == "右对齐" then
                    line.align = 3
                end
            end

            line.effect = line.effect .. "-roller"
            -- 将修改后的行添加到列表中
            line.comment = false
            line.layer = 0  -- 放在同一层中
            line.index = #roller_lines  -- 用于快排不改变原顺序
            style_used[line.style]=true
            line.style = line.style
            -- line.style = line.style .. "_" .. target_effect .."-roller"      -- 修改样式：目前不需要


            table.insert(roller_lines, line)

            -- 注释修改前的行
            local line_previous = subtitles[i]
            line_previous.comment = true
            subtitles[i] = line_previous
        end
    end 

    -- 增加样式：目前不需要
    -- len = #subtitles
    -- for i = 1, len do
    --     local line = subtitles[i]
    --     if line.class == "style" and style_used[line.name]~= nil then   -- 即使注释了也会执行操作

    --         -- 创建新的样式 'style_tag-roller'
    --         local new_style = line
    --         new_style.name = new_style.name .. "_" .. target_effect .."-roller"
    --         if xres ~= nil then
    --             new_style.margin_l = bound[1][1]
    --             new_style.margin_r = xres - bound[2][1]    -- width-round[2][1]
    --         end

    --         -- 将新的样式添加到样式表
    --         table.insert(new_styles, line)
    --     end
    -- end 

    -- 按开始时间排序
    table.sort(roller_lines, function(a, b) return a.start_time < b.start_time or (a.start_time == b.start_time and a.index < b.index) end)   -- 默认以原来顺序排列
    
    
    for _, line in ipairs(new_styles) do
        subtitles.append(line)
    end
    
    -- 将处理后的行写入字幕文件中
    if #roller_lines == 0 then
        aegisub.log(2,"没有可生成的行\n")
    else
        lines_dealt = deal_with_time(styles, roller_lines, configs, bound)
        for _, line in ipairs(lines_dealt) do
            subtitles.append(line)
        end
    end

end

function lyrics_roller_recover(subtitles, configs)
    -- 设置指定的特效字符串
    local target_effect = configs.tag
    -- 初始化 meta 和 styles
    local meta, styles = karaskel.collect_head(subtitles)

    local len = #subtitles
    -- 遍历字幕文件中的每一行
    for i = 1, len do
        local line = subtitles[i]

        -- 删除之前增加的字幕和样式
        -- while line.class == "dialogue" and line.effect == target_effect .. "-roller" or line.class == "style" and line.name:find("_" .. target_effect .."%-roller$") do
        while line.class == "dialogue" and line.effect:find("^" .. target_effect ..".*%-roller$") do
            subtitles.delete(i)
            len = len - 1
            if i == len + 1 then
                break
            end
            line = subtitles[i]
        end
        if i == len + 1 then
            break
        end


        if line.class == "dialogue" and (line.effect == target_effect or line.effect:find("^" .. target_effect .."%-[LCRlcr]$")) then   -- 即使注释了也会执行操作
            -- 取消注释 行
            local line_previous = subtitles[i]
            line_previous.comment = false
            subtitles[i] = line_previous
        end
    end 

end

function table2str(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        local key = type(k) == "string" and string.format("[%q]", k) or "[" .. k .. "]"
        local value
        if type(v) == "table" then
            value = table2str(v)
        elseif type(v) == "string" then
            value = string.format("%q", v)
        else
            value = tostring(v)
        end
        result = result .. key .. "=" .. value .. ","
    end
    return result .. "}"
end

function save_config(config)
    local file = io.open(config_file, "w+")
    if file then
        file:write("return " .. table2str(config))
        file:close()
        return true
    else
        return false
    end
end

function load_config()
    local file = io.open(config_file, "r")
    local config = nil
    if file then

        local content = file:read("*a")  -- 读取整个文件
        file:close()
        
        local result = load(content)
        config = result()
    end
    return config
end

function change_config(config, change_config)
    config[2].value = change_config["tag"]
    config[5].value = change_config["bound_1x"]
    config[6].value = change_config["bound_1y"]
    config[8].value = change_config["bound_2x"]
    config[9].value = change_config["bound_2y"]

    config[13].value = change_config["color"]
    config[15].value = change_config["position"]
    config[17].value = change_config["scale"]
    config[19].value = change_config["times"]

    config[22].value = change_config["color_norm"]
    config[24].value = change_config["opacity"]
    config[26].value = change_config["spacing"]
    config[28].value = change_config["spacing_inner"]
    config[30].value = change_config["align"]
    config[32].value = change_config["fade_in"]
    config[34].value = change_config["fade_out"]
    config[35].value = change_config["edge_fade"]
    config[36].value = change_config["karaok"]
    config[37].value = change_config["save_config"]
end

function generate(subtitles, selected_lines)

    config = util.deep_copy(generate_config)
    result = load_config()
    if result ~= nil then
        aegisub.log(3,"读取参数\n")
        change_config(config, result)
    else 
        aegisub.log(3,"使用默认参数\n")
        local xres, yres = aegisub.video_size()
        if xres ~= nil then
            config[8].value = xres
        end
        if yres ~= nil then
            config[9].value = yres
        end     
    end

    btn,result = aegisub.dialog.display(config,{"ok","cancel","reset to default"},
        {ok="ok", cancel="cancel"})

    while btn == "reset to default" do
        aegisub.log(3,"参数恢复默认\n")
        os.remove(config_file)
        config = util.deep_copy(generate_config)
        local xres, yres = aegisub.video_size()
        if xres ~= nil then
            config[8].value = xres
        end
        if yres ~= nil then
            config[9].value = yres
        end     
        
        btn,result = aegisub.dialog.display(config,{"ok","cancel","reset to default"},
            {ok="ok", cancel="cancel"})
    end
    
    if btn =="ok" then
        if result.save_config == true then
            if save_config(result) then
                aegisub.log(3,"保存参数成功\n")
            else
                aegisub.log(3,"保存参数失败\n")
            end
        end
        lyrics_roller(subtitles,result)
        aegisub.log(3,"生成结束\n")
    else
        aegisub.log(3,"取消操作\n")
    end
    aegisub.set_undo_point("滚动歌词生成")
end

function recover(subtitles, selected_lines)

    btn,result = aegisub.dialog.display(recover_config,{"ok","cancel"},
    {ok="ok", cancel="cancel"})
    
    if btn=="ok" then
        lyrics_roller_recover(subtitles,result)
        aegisub.log(3,"复原成功\n")
    else
        aegisub.log(3,"取消操作\n")
    end
    aegisub.set_undo_point("滚动歌词复原")
end


for i = 1, #all_macros do
	aegisub.register_macro(script_name.."/"..all_macros[i]["script_name"], all_macros[i]["script_description"], all_macros[i]["entry"], all_macros[i]["validation"])
end
