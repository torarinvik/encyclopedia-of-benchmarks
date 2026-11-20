const
  MaxN = 100_000'i64
  MaxParseableLength = 2

proc digitSum(valueArg: int64): int64 =
  var value = valueArg
  var total = 0'i64
  while value > 0:
    total += value mod 10
    value = value div 10
  total

proc digitProduct(valueArg: int64): int64 =
  var value = valueArg
  var product = 1'i64
  while value > 0:
    product *= value mod 10
    value = value div 10
  product

proc digitalRoot(valueArg: int64): int64 =
  var value = valueArg
  while value >= 10:
    value = digitSum(value)
  value

proc multiplicativeRoot(valueArg: int64): int64 =
  var value = valueArg
  while value >= 10:
    value = digitProduct(value)
  value

proc isDividuus(n: int64): bool =
  let sum = digitSum(n)
  let product = digitProduct(n)
  let root = digitalRoot(n)
  let mroot = multiplicativeRoot(n)
  if sum == 0 or product == 0 or root == 0 or mroot == 0: return false
  n mod sum == 0 and n mod product == 0 and n mod root == 0 and n mod mroot == 0

proc dividuus_number_predicate*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dividuus_number_predicate".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxN: return -1
  if isDividuus(input[0]): return 1
  0
