## Classify capitalization by counting uppercase letters.
const MaxLength = 1024

proc isUpper(value: int64): bool = value >= 65 and value <= 90
proc isLower(value: int64): bool = value >= 97 and value <= 122

proc detect_capital_usage*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "detect_capital_usage".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  var uppercaseCount = 0
  for index in 0 ..< int(length):
    let value = input[index]
    if not isUpper(value) and not isLower(value): return -1
    if isUpper(value): uppercaseCount += 1
  if uppercaseCount == 0 or uppercaseCount == int(length) or
      (uppercaseCount == 1 and length != 0 and isUpper(input[0])): return 1
  return 0
