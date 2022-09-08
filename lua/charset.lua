--[[

关于CJK扩展字符
  CJK = 中日韩（China, Japan, Korea），这个主要是指的东亚地区使用汉字及部分衍生偏僻字的字符集
  （由于其使用频率非常低，一般的电脑系统里没有相关的字符，因此不能显示这些字）

查询unicode 编码
  1. https://unicode.org/charts/

导出函数
  1. charset_filter: 滤除含 CJK 扩展汉字的候选项
  2. charset_comment_filter: 为候选项加上其所属字符集的注释

--]]

local charset = {
  ["CJK"] = { first = 0x4E00, last = 0x9FFF },     -- CJK Unified Ideographs - https://unicode.org/charts/PDF/U4E00.pdf
  ["ExtA"] = { first = 0x3400, last = 0x4DBF },    -- CJK Unified Ideographs Extension A - https://unicode.org/charts/PDF/U3400.pdf
  ["ExtB"] = { first = 0x20000, last = 0x2A6DF },  -- CJK Unified Ideographs Extension B - https://unicode.org/charts/PDF/U20000.pdf
  ["ExtC"] = { first = 0x2A700, last = 0x2B73F },  -- CJK Unified Ideographs Extension C - https://unicode.org/charts/PDF/U2A700.pdf
  ["ExtD"] = { first = 0x2B740, last = 0x2B81F },  -- CJK Unified Ideographs Extension D - https://unicode.org/charts/PDF/U2B740.pdf
  ["ExtE"] = { first = 0x2B820, last = 0x2CEAF },  -- CJK Unified Ideographs Extension E - https://unicode.org/charts/PDF/U2B820.pdf
  ["ExtF"] = { first = 0x2CEB0, last = 0x2EBEF },  -- CJK Unified Ideographs Extension F - https://unicode.org/charts/PDF/U2CEB0.pdf
  ["ExtG"] = { first = 0x30000, last = 0x3134A },  -- CJK Unified Ideographs Extension G - https://unicode.org/charts/PDF/U30000.pdf
  ["Compat"] = { first = 0x2F800, last = 0x2FA1F } -- CJK Compatibility Ideographs Supplement - https://unicode.org/charts/PDF/U2F800.pdf
}

local function exists(single_filter, text)
  for i in utf8.codes(text) do
    local c = utf8.codepoint(text, i)
    if (not single_filter(c)) then
      return false
    end
  end
  return true
end

local function is_charset(s)
  return function (c)
    return c >= charset[s].first and c <= charset[s].last
  end
end

--[[
滤除含 CJK 扩展汉字的候选项：
--]]
local function charset_filter(input)
  -- 使用 `iter()` 遍历所有输入候选项
  for cand in input:iter() do
    -- 如果当前候选项 `cand` 不含 CJK 扩展汉字
    if (not exists(is_cjk_ext, cand.text))
    then
      -- 结果中仍保留此候选
      yield(cand)
    end
    --[[ 上述条件不满足时，当前的候选 `cand` 没有被 yield。
      因此过滤结果中将不含有该候选。
    --]]
  end
end

--[[
为候选项加上其所属字符集的注释：
--]]
local function charset_comment_filter(input, env)
  local option = env.engine.context:get_option("option_charset_comment_filter") -- 开关
  -- 使用 `iter()` 遍历所有输入候选项
  for cand in input:iter() do
    if(option)
    then
      -- 判断当前候选内容 `cand.text` 中文字属哪个字符集
      -- s key
      -- r value
      for s, r in pairs(charset) do
        if (exists(is_charset(s), cand.text)) then
        --[[ 修改候选的注释 `cand.comment`
          因复杂类型候选项的注释不能被直接修改，
          因此使用 `get_genuine()` 得到其对应真实的候选项
        --]]
          cand:get_genuine().comment = "|" .. s .. "| " .. cand.comment
          break
        end
      end
    end -- option
    -- 在结果中对应产生一个带注释的候选
    yield(cand)
  end
end

return { 
  filter = charset_filter,
  comment_filter = charset_comment_filter 
}