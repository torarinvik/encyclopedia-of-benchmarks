const
  MaxParseableLength = 2
  MaxN = 30'i64

proc riordanNumberValue(n: int): int64 =
  var values: array[31, int64]
  values[0] = 1
  var size = 2
  while size <= n:
    values[size] = int64(size - 1) * (2 * values[size - 1] + 3 * values[size - 2]) div int64(size + 1)
    inc size
  values[n]

proc solve(input: ptr UncheckedArray[int64], length: int): int64 =
  if length < 1 or length > MaxParseableLength: return -1
  let n = input[0]
  if length != 1 or n < 0 or n > MaxN: return -1
  riordanNumberValue(int(n))

proc riordan_number*(input: ptr UncheckedArray[int64],
                     length: csize_t): int64
    {.cdecl, exportc: "riordan_number".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  solve(input, int(length))
