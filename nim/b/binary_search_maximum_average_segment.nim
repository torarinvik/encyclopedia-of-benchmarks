const MaxN = 32
const MaxInput = 35
const InvalidResult = -1_000_001'i64

proc feasible(input: ptr UncheckedArray[int64], n, minimumLength: int,
              threshold: int64): bool =
  var prefix: array[33, int64]
  for index in 0 ..< n:
    prefix[index + 1] = prefix[index] + 1000'i64 * input[index + 2] - threshold
  var minimumPrefix = high(int64)
  for finish in minimumLength .. n:
    let eligibleStart = finish - minimumLength
    if prefix[eligibleStart] < minimumPrefix:
      minimumPrefix = prefix[eligibleStart]
    if prefix[finish] >= minimumPrefix:
      return true
  false

proc binary_search_maximum_average_segment*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_search_maximum_average_segment".} =
  if input.isNil or length < 3 or length > MaxInput:
    return InvalidResult
  let nValue = input[0]
  let minimumValue = input[1]
  if nValue < 1 or nValue > MaxN or minimumValue < 1 or minimumValue > nValue:
    return InvalidResult
  let n = int(nValue)
  if int(length) != n + 2:
    return InvalidResult
  for index in 0 ..< n:
    if input[index + 2] < -1000 or input[index + 2] > 1000:
      return InvalidResult

  var low = -1_000_000'i64
  var high = 1_000_001'i64
  while high - low > 1:
    let middle = low + (high - low) div 2
    if feasible(input, n, int(minimumValue), middle):
      low = middle
    else:
      high = middle
  low
