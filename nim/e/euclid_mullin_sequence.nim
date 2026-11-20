const MaxParseableLength = 2
const MaxN = 8'i64

proc leastPrimeFactor(value: int64): int64 =
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return divisor
    inc divisor
  value

proc euclidMullinTerm(index: int64): int64 =
  var product = 1'i64
  var term = 1'i64
  for position in 0'i64 ..< index:
    term = leastPrimeFactor(product + 1)
    product *= term
  term

proc euclid_mullin_sequence*(input: ptr UncheckedArray[int64],
    length: csize_t): int64
    {.cdecl, exportc: "euclid_mullin_sequence".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxN: return -1
  euclidMullinTerm(input[0])
