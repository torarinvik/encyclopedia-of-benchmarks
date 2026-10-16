import math

const MaxTime = 32
const MaxClasses = 16
const MaxTarget = 16
const MaxInputLength = 3 + MaxTarget + MaxTime * MaxClasses
const MaxStates = 33
const NegInf = -1.0e300
const InvalidResult = -1.0e300

proc logAddExp(left, right: float64): float64 =
  if left <= NegInf / 2: return right
  if right <= NegInf / 2: return left
  let larger = max(left, right)
  let smaller = min(left, right)
  larger + ln(1.0 + exp(smaller - larger))

proc connectionist_temporal_classification_loss*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "connectionist_temporal_classification_loss".} =
  if values == nil or length < 3 or length > MaxInputLength: return InvalidResult
  let timeValue = values[0]
  let classesValue = values[1]
  let targetValue = values[2]
  if timeValue < 1 or timeValue > MaxTime or classesValue < 2 or classesValue > MaxClasses or
      targetValue < 1 or targetValue > MaxTarget: return InvalidResult
  let time = int(timeValue)
  let classes = int(classesValue)
  let targetLength = int(targetValue)
  let probabilityBase = 3 + targetLength
  if length != csize_t(probabilityBase + time * classes): return InvalidResult
  var repeated = 0
  for i in 0 ..< targetLength:
    let target = values[3 + i]
    if target < 1 or target >= int64(classes): return InvalidResult
    if i > 0 and target == values[3 + i - 1]: inc repeated
  if time < targetLength + repeated: return InvalidResult
  for t in 0 ..< time:
    var rowSum: int64 = 0
    for c in 0 ..< classes:
      let p = values[probabilityBase + t * classes + c]
      if p < 1 or p > 1_000_000: return InvalidResult
      rowSum += p
    if rowSum != 1_000_000: return InvalidResult

  let states = 2 * targetLength + 1
  var extended: array[MaxStates, int64]
  var previous: array[MaxStates, float64]
  var current: array[MaxStates, float64]
  for s in 0 ..< states:
    extended[s] = if s mod 2 == 0: 0 else: values[3 + s div 2]
    previous[s] = NegInf
  previous[0] = ln(float64(values[probabilityBase]) / 1_000_000.0)
  previous[1] = ln(float64(values[probabilityBase + int(extended[1])]) / 1_000_000.0)
  for t in 1 ..< time:
    for s in 0 ..< states:
      var incoming = previous[s]
      if s > 0: incoming = logAddExp(incoming, previous[s - 1])
      if s > 1 and extended[s] != extended[s - 2]: incoming = logAddExp(incoming, previous[s - 2])
      let p = float64(values[probabilityBase + t * classes + int(extended[s])]) / 1_000_000.0
      current[s] = incoming + ln(p)
    for s in 0 ..< states: previous[s] = current[s]
  -logAddExp(previous[states - 1], previous[states - 2])
