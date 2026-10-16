## mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units.
proc string_prefix_suffix*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "string_prefix_suffix".} =
  if values == nil or length < 3 or length > 2052: return -1
  let mode = values[0]
  let textCountValue = values[1]
  let patternCountValue = values[2]
  if (mode != 0 and mode != 1) or textCountValue < 0 or textCountValue > 1024 or
      patternCountValue < 0 or patternCountValue > 1024: return -1
  let textCount = int(textCountValue)
  let patternCount = int(patternCountValue)
  if length != csize_t(3 + textCount + patternCount): return -1
  for index in 0 ..< textCount + patternCount:
    let unit = values[3 + index]
    if unit < 0 or unit > 65535: return -1
  if patternCount > textCount: return 0
  let start = if mode == 0: 0 else: textCount - patternCount
  for index in 0 ..< patternCount:
    if values[3 + start + index] != values[3 + textCount + index]: return 0
  1
