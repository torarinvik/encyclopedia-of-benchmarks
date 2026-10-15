const MaxSamples = 256
const MaxLevels = 16
const MaxBuckets = 5
const BucketCapacity = MaxBuckets + 1
const MinSubwindow = 5'i64
const InputScale = 1_000_000_000.0

type Adwin = object
  sizes: array[MaxLevels, int]
  totals: array[MaxLevels, array[BucketCapacity, float64]]
  variances: array[MaxLevels, array[BucketCapacity, float64]]
  width: int64
  total: float64
  variance: float64
  bucketCount: int
  delta: float64

proc adwinSqrt(value: float64): float64 =
  if value <= 0.0: return 0.0
  var root = if value > 1.0: value else: 1.0
  for _ in 0 ..< 80: root = 0.5 * (root + value / root)
  root

proc adwinLn(valueInput: float64): float64 =
  var value = valueInput
  var exponent = 0
  while value >= 2.0:
    value *= 0.5
    inc exponent
  let ratio = (value - 1.0) / (value + 1.0)
  let square = ratio * ratio
  var term = ratio
  var sum = 0.0
  for iteration in 0 ..< 40:
    sum += term / float64(2 * iteration + 1)
    term *= square
  2.0 * sum + float64(exponent) * 0.693147180559945309417232121458176568

proc addBucket(state: var Adwin, level: int, total: float64, variance: float64) =
  let slot = state.sizes[level]
  state.totals[level][slot] = total
  state.variances[level][slot] = variance
  inc state.sizes[level]

proc removeOldest(state: var Adwin, level: int, count: int) =
  let oldSize = state.sizes[level]
  for i in count ..< oldSize:
    state.totals[level][i - count] = state.totals[level][i]
    state.variances[level][i - count] = state.variances[level][i]
  state.sizes[level] -= count

proc compress(state: var Adwin) =
  for level in 0 ..< MaxLevels - 1:
    if state.sizes[level] <= MaxBuckets: break
    let size = float64(1 shl level)
    let firstMean = state.totals[level][0] / size
    let secondMean = state.totals[level][1] / size
    let difference = firstMean - secondMean
    let mergedVariance = state.variances[level][0] + state.variances[level][1] +
      size * size * difference * difference / (size + size)
    let mergedTotal = state.totals[level][0] + state.totals[level][1]
    addBucket(state, level + 1, mergedTotal, mergedVariance)
    removeOldest(state, level, 2)
    dec state.bucketCount

proc insert(state: var Adwin, value: float64) =
  inc state.width
  addBucket(state, 0, value, 0.0)
  inc state.bucketCount
  if state.width > 1:
    let deviation = value - state.total / float64(state.width - 1)
    state.variance += float64(state.width - 1) * deviation * deviation / float64(state.width)
  state.total += value
  compress(state)

proc significant(state: Adwin, oldWidth: int64, recentWidth: int64, difference: float64): bool =
  let harmonic = 1.0 / float64(oldWidth - MinSubwindow + 1) +
    1.0 / float64(recentWidth - MinSubwindow + 1)
  let confidence = adwinLn(2.0 * adwinLn(float64(state.width)) / state.delta)
  let windowVariance = state.variance / float64(state.width)
  let epsilon = adwinSqrt(2.0 * harmonic * windowVariance * confidence) +
    2.0 / 3.0 * confidence * harmonic
  abs(difference) > epsilon

proc dropOldest(state: var Adwin) =
  var level = MaxLevels - 1
  while level > 0 and state.sizes[level] == 0: dec level
  let size = int64(1 shl level)
  let bucketTotal = state.totals[level][0]
  state.width -= size
  state.total -= bucketTotal
  if state.width > 0:
    let bucketMean = bucketTotal / float64(size)
    let difference = bucketMean - state.total / float64(state.width)
    state.variance -= state.variances[level][0] + float64(size) * float64(state.width) *
      difference * difference / float64(size + state.width)
  else:
    state.variance = 0.0
  if state.variance < 0.0: state.variance = 0.0
  removeOldest(state, level, 1)
  dec state.bucketCount

proc detectChange(state: var Adwin): bool =
  var changed = false
  var searching = true
  while searching and state.width >= 2 * MinSubwindow:
    searching = false
    var stop = false
    var oldWidth = 0'i64
    var oldTotal = 0.0
    for level in countdown(MaxLevels - 1, 0):
      for bucket in 0 ..< state.sizes[level]:
        if level == 0 and bucket == state.sizes[level] - 1:
          stop = true
          break
        oldWidth += int64(1 shl level)
        oldTotal += state.totals[level][bucket]
        let recentWidth = state.width - oldWidth
        let recentTotal = state.total - oldTotal
        if recentWidth < MinSubwindow:
          stop = true
          break
        if oldWidth >= MinSubwindow and significant(state, oldWidth, recentWidth,
            oldTotal / float64(oldWidth) - recentTotal / float64(recentWidth)):
          changed = true
          searching = true
          dropOldest(state)
          stop = true
          break
      if stop: break
  changed

proc writeI64(output: ptr UncheckedArray[uint8], wordIndex: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[8 * wordIndex + byte] = uint8((bits shr (8 * byte)) and 255)

proc adwin*(input: ptr UncheckedArray[int64], length: csize_t,
            output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adwin".} =
  if input == nil or length < 3 or length > csize_t(2 + MaxSamples): return -1
  let sampleCountValue = input[0]
  let deltaValue = input[1]
  if sampleCountValue < 1 or sampleCountValue > MaxSamples or
      length != csize_t(2 + int(sampleCountValue)) or deltaValue < 1 or deltaValue > 100_000_000:
    return -1
  let sampleCount = int(sampleCountValue)
  for i in 0 ..< sampleCount:
    if input[2 + i] < -1_000_000_000'i64 or input[2 + i] > 1_000_000_000'i64: return -1
  if output == nil or outputCapacity < csize_t(16 * sampleCount): return -2

  var state: Adwin
  state.delta = float64(deltaValue) / InputScale
  for i in 0 ..< sampleCount:
    state.insert(float64(input[2 + i]) / InputScale)
    let flag = if state.detectChange(): 1'i64 else: 0'i64
    writeI64(output, 2 * i, flag)
    writeI64(output, 2 * i + 1, state.width)
  int64(2 * sampleCount)
