const Scale = 1_000_000'i64
const MaxEndpointMicro = 1_000_000'i64
const MaxSteps = 10_000'i64
const InvalidResult = -1.0e300

proc sampleValue(functionId: int64, x: float64): float64 =
  if functionId == 0: x * x else: x * x * x

proc trapezoidal_integration*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "trapezoidal_integration".} =
  if values == nil or length != 4: return InvalidResult
  let startMicro = values[0]
  let endMicro = values[1]
  let steps = values[2]
  let functionId = values[3]
  if startMicro < -MaxEndpointMicro or startMicro > MaxEndpointMicro or
      endMicro < -MaxEndpointMicro or endMicro > MaxEndpointMicro or
      steps < 1 or steps > MaxSteps or functionId < 0 or functionId > 1:
    return InvalidResult

  let start = float64(startMicro) / float64(Scale)
  let end = float64(endMicro) / float64(Scale)
  let delta = (end - start) / float64(steps)
  var total = 0.0
  var index = 0'i64
  while index < steps:
    let left = start + delta * float64(index)
    let right = left + delta
    let midpoint = (sampleValue(functionId, left) + sampleValue(functionId, right)) * 0.5
    total += midpoint * delta
    inc index
  total
