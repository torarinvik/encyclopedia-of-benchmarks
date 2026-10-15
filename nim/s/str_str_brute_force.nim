## Return the first pattern occurrence using a direct character-by-character scan.
const MaxStringLength = 1024

proc str_str_brute_force*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "str_str_brute_force".} =
  if packed == nil or length < 2 or length > csize_t(2 + 2 * MaxStringLength): return -1
  if packed[0] < 0 or packed[0] > MaxStringLength or
      packed[1] < 0 or packed[1] > MaxStringLength: return -1
  let textLength = int(packed[0])
  let patternLength = int(packed[1])
  if int(length) != 2 + textLength + patternLength: return -1
  for index in 0 ..< textLength + patternLength:
    if packed[2 + index] < 1 or packed[2 + index] > 127: return -1
  if patternLength == 0: return 0
  if patternLength > textLength: return -1

  let patternStart = 2 + textLength
  for start in 0 .. (textLength - patternLength):
    var offset = 0
    while offset < patternLength and packed[2 + start + offset] == packed[patternStart + offset]:
      inc offset
    if offset == patternLength: return int64(start)
  -1
