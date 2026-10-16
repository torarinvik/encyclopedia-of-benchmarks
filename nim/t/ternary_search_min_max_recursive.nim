const InvalidResult = -1.0e300

proc minimumFunction(x: float32): float32 = x * x - 2.0'f32 * x + 3.0'f32
proc maximumFunction(x: float32): float32 = -x * x - 2.0'f32 * x + 3.0'f32

proc ternaryMin(start, finish, precision: float32): float32 =
  let width = finish - start
  let absoluteWidth = if width < 0.0'f32: -width else: width
  if absoluteWidth >= precision:
    let mid1 = start + width / 3.0'f32
    let mid2 = finish - width / 3.0'f32
    let r1 = minimumFunction(mid1)
    let r2 = minimumFunction(mid2)
    if r1 < r2: return ternaryMin(start, mid2, precision)
    if r1 > r2: return ternaryMin(mid1, finish, precision)
    return ternaryMin(mid1, mid2, precision)
  minimumFunction(start)

proc ternaryMax(start, finish, precision: float32): float32 =
  let width = finish - start
  let absoluteWidth = if width < 0.0'f32: -width else: width
  if absoluteWidth >= precision:
    let mid1 = start + width / 3.0'f32
    let mid2 = finish - width / 3.0'f32
    let r1 = maximumFunction(mid1)
    let r2 = maximumFunction(mid2)
    if r1 < r2: return ternaryMax(mid1, finish, precision)
    if r1 > r2: return ternaryMax(start, mid2, precision)
    return ternaryMax(mid1, mid2, precision)
  maximumFunction(start)

proc ternary_search_min_max_recursive*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "ternary_search_min_max_recursive".} =
  if values == nil or length != 4: return InvalidResult
  let mode = values[0]
  let startMilli = values[1]
  let endMilli = values[2]
  let precisionMilli = values[3]
  let centerMilli = if mode == 0: 1000'i64 elif mode == 1: -1000'i64 else: 0'i64
  if mode < 0 or mode > 1 or startMilli < -100000 or endMilli > 100000 or
      startMilli >= centerMilli or endMilli <= centerMilli or precisionMilli < 1 or precisionMilli > 8:
    return InvalidResult
  let start = float32(startMilli) / 1000.0'f32
  let finish = float32(endMilli) / 1000.0'f32
  let precision = float32(precisionMilli) / 1000.0'f32
  if mode == 0: float64(ternaryMin(start, finish, precision))
  else: float64(ternaryMax(start, finish, precision))
