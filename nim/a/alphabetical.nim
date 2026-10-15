## Check whether an ASCII letter string is case-insensitively sorted.
proc isAsciiLetter(value: int64): bool =
  (value >= ord('A') and value <= ord('Z')) or (value >= ord('a') and value <= ord('z'))

proc lowercaseAscii(value: int64): int64 =
  if value >= ord('A') and value <= ord('Z'): value + 32 else: value

proc alphabetical*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "alphabetical".} =
  if length > 256 or (length != 0 and values == nil): return -1
  var index: csize_t = 0
  while index < length:
    let value = values[index]
    if value < 0 or value > 127: return -1
    inc index
  if length == 0: return 0
  var previous = -1'i64
  index = 0
  while index < length:
    let value = values[index]
    if not isAsciiLetter(value): return 0
    let current = lowercaseAscii(value)
    if current < previous: return 0
    previous = current
    inc index
  return 1
