## Recheck the whole word for every uppercase byte after the first.
const MaxLength = 1024

proc isUpper(value: int64): bool = value >= 65 and value <= 90
proc isLower(value: int64): bool = value >= 97 and value <= 122

proc detect_capital_usage_scan*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "detect_capital_usage_scan".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if not isUpper(input[index]) and not isLower(input[index]): return -1
  for index in 1 ..< int(length):
    if isUpper(input[index]):
      var allUpper = true
      for check in 0 ..< int(length):
        if isLower(input[check]):
          allUpper = false
          break
      if not allUpper: return 0
  1
