const MaxN = 10'i64
const SearchMax = 64'i64
const MaxParseableLength = 2

proc isPrimeTrial(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc fortunateTerm(n: int64): int64 =
  var primorial = 1'i64
  var primesFound = 0'i64
  var candidate = 2'i64
  while primesFound < n:
    if isPrimeTrial(candidate):
      primorial *= candidate
      inc primesFound
    inc candidate
  var offset = 2'i64
  while offset <= SearchMax:
    if isPrimeTrial(primorial + offset): return offset
    inc offset
  -2

proc fortunate_numbers*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fortunate_numbers".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxN: return -1
  fortunateTerm(input[0])
