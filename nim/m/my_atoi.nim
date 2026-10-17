const MaxInputLength = 256
const Int32MaxValue = 2147483647'i64
const Int32MinMagnitude = 2147483648'i64
const InvalidResult = low(int64)

proc my_atoi*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "my_atoi".} =
  if input == nil: return 0
  if length > csize_t(MaxInputLength): return InvalidResult
  for i in 0 ..< int(length):
    if input[i] < 0 or input[i] > 127: return InvalidResult

  var start = 0
  var finish = int(length)
  while start < finish and input[start] <= 32: inc start
  while finish > start and input[finish - 1] <= 32: dec finish
  if start == finish: return 0

  var negative = false
  if input[start] == 43 or input[start] == 45:
    negative = input[start] == 45
    inc start
  let limit = if negative: Int32MinMagnitude else: Int32MaxValue
  var magnitude = 0'i64
  while start < finish and input[start] >= 48 and input[start] <= 57:
    let digit = input[start] - 48
    if magnitude > limit div 10 or (magnitude == limit div 10 and digit > limit mod 10):
      return if negative: -Int32MinMagnitude else: Int32MaxValue
    magnitude = magnitude * 10 + digit
    inc start
  if negative: -magnitude else: magnitude
