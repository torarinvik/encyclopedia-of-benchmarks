## Composite trapezoidal integration for constant, linear, and quadratic samples.
const MaxSteps = 10000
const MaxCoordMilli = 100000
const OutputScale = 1_000_000.0

func sampleValue(functionId: int64, x: float64): float64 =
  case functionId
  of 0: 5.0
  of 1: x
  else: x * x

proc area_under_curve*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "area_under_curve".} =
  if input == nil or length != 4: return -1
  let functionId = input[0]
  let startMilli = input[1]
  let endMilli = input[2]
  let steps = input[3]
  if functionId < 0 or functionId > 2 or startMilli < 0 or startMilli > MaxCoordMilli or
      endMilli < 0 or endMilli > MaxCoordMilli or steps < 1 or steps > MaxSteps: return -1
  let lowMilli = min(startMilli, endMilli)
  let highMilli = max(startMilli, endMilli)
  let start = float64(lowMilli) / 1000.0
  let ending = float64(highMilli) / 1000.0
  let width = (ending - start) / float64(steps)
  var x1 = start
  var y1 = sampleValue(functionId, x1)
  var area = 0.0
  for _ in 0 ..< int(steps):
    let x2 = x1 + width
    let y2 = sampleValue(functionId, x2)
    area += (y1 + y2) * width * 0.5
    x1 = x2
    y1 = y2
  int64(area * OutputScale + 0.5)
