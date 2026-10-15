const MaxLength = 4096

proc isAsciiWord(value: int64): bool =
  (value >= ord('a').int64 and value <= ord('z').int64) or
  (value >= ord('A').int64 and value <= ord('Z').int64) or
  (value >= ord('0').int64 and value <= ord('9').int64)

proc check_kebab_case*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_kebab_case".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -2
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -2
  for index in 0 ..< int(length):
    if values[index] == ord('_').int64: return 0
  if length < 3: return 0
  for index in 1 ..< int(length) - 1:
    if values[index] == ord('-').int64 and isAsciiWord(values[index - 1]) and isAsciiWord(values[index + 1]):
      return 1
  return 0
