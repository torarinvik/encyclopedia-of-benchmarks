## Check the bounded ASCII Pascal-case predicate.
const MaxLength = 4096

proc check_pascal_case*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_pascal_case".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -2
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -2
  if length == 0 or values[0] < 65 or values[0] > 90: return 0
  for index in 0 ..< int(length):
    let value = values[index]
    if not ((value >= 97 and value <= 122) or (value >= 65 and value <= 90)): return 0
  1
