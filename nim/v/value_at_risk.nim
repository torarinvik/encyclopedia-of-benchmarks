const Scale = 1_000_000'i64
const MaxReturns = 64
const MaxParsedReturns = 65
const MaxSample = 1_000_000_000'i64
const MaxInputLength = 67
const InvalidResult = -1.0e300

proc siftDown(values: var array[MaxReturns, float64], rootStart, endValue: int) =
  var root = rootStart
  while root < endValue div 2:
    var child = root * 2 + 1
    if child + 1 < endValue and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc heapSort(values: var array[MaxReturns, float64], length: int) =
  for start in countdown(length div 2 - 1, 0): siftDown(values, start, length)
  for ending in countdown(length - 1, 1):
    swap(values[0], values[ending])
    siftDown(values, 0, ending)

proc value_at_risk*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "value_at_risk".} =
  if input == nil or length < 2 or length > MaxInputLength: return InvalidResult
  let confidenceMicro = input[0]
  let countValue = input[1]
  if confidenceMicro < 1 or confidenceMicro >= Scale or countValue < 1 or countValue > MaxParsedReturns: return InvalidResult
  if length != csize_t(2 + countValue) or countValue > int64(MaxReturns): return InvalidResult
  let count = int(countValue)
  var returns: array[MaxReturns, float64]
  for index in 0 ..< count:
    let value = input[2 + index]
    if value < -MaxSample or value > MaxSample: return InvalidResult
    returns[index] = float64(value) / float64(Scale)
  heapSort(returns, count)
  let confidence = float64(confidenceMicro) / float64(Scale)
  let quantile = 1.0 - confidence
  let position = float64(count - 1) * quantile
  let lower = int(position)
  let fraction = position - float64(lower)
  let threshold = if lower == count - 1: returns[count - 1] else: returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction
    -threshold
