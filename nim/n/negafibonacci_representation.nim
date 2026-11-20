type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

const MaxIndex = 17
const ValueLimit = 1000'i64

proc encode(value: int64, output: var array[MaxIndex, uint8]): int =
  var fib: array[MaxIndex + 1, int64]
  var weight: array[MaxIndex + 1, int64]
  var low: array[MaxIndex + 1, int64]
  var high: array[MaxIndex + 1, int64]
  var digit: array[MaxIndex + 1, uint8]
  fib[1] = 1
  fib[2] = 1
  for k in 3..MaxIndex: fib[k] = fib[k - 1] + fib[k - 2]
  for k in 1..MaxIndex:
    weight[k] = if k mod 2 == 1: fib[k] else: -fib[k]
  for k in 1..MaxIndex:
    let suffixLow = if k == 1: 0'i64 else: low[k - 2]
    let suffixHigh = if k == 1: 0'i64 else: high[k - 2]
    low[k] = min(low[k - 1], weight[k] + suffixLow)
    high[k] = max(high[k - 1], weight[k] + suffixHigh)
  var remaining = value
  var selectedAbove = false
  for k in countdown(MaxIndex, 1):
    var choose = false
    if not selectedAbove:
      let suffixLow = if k == 1: 0'i64 else: low[k - 2]
      let suffixHigh = if k == 1: 0'i64 else: high[k - 2]
      let candidate = remaining - weight[k]
      choose = suffixLow <= candidate and candidate <= suffixHigh
    if choose:
      digit[k] = 1
      remaining -= weight[k]
    selectedAbove = choose
  var highest = MaxIndex
  while highest > 1 and digit[highest] == 0: dec highest
  for k in countdown(highest, 1):
    output[highest - k] = if digit[k] == 1: uint8('1') else: uint8('0')
  highest

proc negafibonacci_representation*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "negafibonacci_representation".} =
  if input == nil or length != 1: return -1
  let value = input[0]
  if value < -ValueLimit or value > ValueLimit: return -1
  var staged: array[MaxIndex, uint8]
  let required = encode(value, staged)
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0..<required: output[index] = staged[index]
  int64(required)
