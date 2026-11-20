const
  MaxParseableLength = 2
  MaxN = 30'i64

proc motzkinNumberValue(n: int): int64 =
  var values: array[31, int64]
  values[0] = 1
  if n >= 1: values[1] = 1
  var size = 2
  while size <= n:
    var total = values[size - 1]
    for left in 0 ..< size - 1:
      total += values[left] * values[size - 2 - left]
    values[size] = total
    inc size
  values[n]

proc solve(input: ptr UncheckedArray[int64], length: int): int64 =
  if length < 1 or length > MaxParseableLength: return -1
  let n = input[0]
  if length != 1 or n < 0 or n > MaxN: return -1
  motzkinNumberValue(int(n))

proc motzkin_number*(input: ptr UncheckedArray[int64],
                     length: csize_t): int64
    {.cdecl, exportc: "motzkin_number".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  solve(input, int(length))
