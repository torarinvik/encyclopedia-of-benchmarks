type I64Array = ptr UncheckedArray[int64]

proc find_second_largest_element*(input: I64Array, length: csize_t): int64
    {.cdecl, exportc: "find_second_largest_element".} =
  const invalid = low(int64)
  if input.isNil or length < 3 or length > 10001: return invalid
  let n = input[0]
  if n < 2 or n > 10000 or length != csize_t(n + 1): return invalid
  var largest = -2_147_483_648'i64
  for i in 0 ..< int(n):
    let value = input[i + 1]
    if value < -2_147_483_648'i64 or value > 2_147_483_647'i64: return invalid
    if value > largest: largest = value
  var second = -2_147_483_649'i64
  for i in 0 ..< int(n):
    let value = input[i + 1]
    if value < largest and value > second: second = value
  if second == -2_147_483_649'i64: return invalid
  second
