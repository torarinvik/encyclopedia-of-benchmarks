import std/math

const InvalidResult = -1.0e300
const MaxInputLength = 36
const MaxSamples = 32

proc realtime_stats*(input: ptr UncheckedArray[int64], inputLength: csize_t): float64
    {.cdecl, exportc: "realtime_stats".} =
  if input.isNil or inputLength < 3 or inputLength > MaxInputLength.csize_t:
    return InvalidResult
  if input[0] < 0 or input[0] > 2 or input[1] < 0 or input[1] > 2 or
      input[2] < 2 or input[2] > MaxSamples:
    return InvalidResult
  let variant = int(input[0])
  let statistic = int(input[1])
  let count = int(input[2])
  if int(inputLength) != 3 + count:
    return InvalidResult
  for index in 0 ..< count:
    if input[3 + index] < -64 or input[3 + index] > 64:
      return InvalidResult

  var mean32 = 0'f32
  var variance32 = 0'f32
  var mean64 = 0'f64
  var variance64 = 0'f64
  if variant == 0:
    var anchor = 0'f32
    var ex = 0'f32
    var ex2 = 0'f32
    var n = 0
    for index in 0 ..< count:
      let x = float32(input[3 + index]) / 16'f32
      if n == 0: anchor = x
      inc n
      let delta = x - anchor
      ex = ex + delta
      ex2 = ex2 + delta * delta
    mean32 = anchor + ex / float32(n)
    variance32 = (ex2 - (ex * ex) / float32(n)) / float32(n - 1)
  elif variant == 1:
    var mu = 0'f32
    var m = 0'f32
    var n = 0
    for index in 0 ..< count:
      let x = float32(input[3 + index]) / 16'f32
      inc n
      let delta = x - mu
      mu = mu + delta / float32(n)
      let delta2 = x - mu
      m = m + delta * delta2
    mean32 = mu
    variance32 = m / float32(n)
  else:
    var mu = 0'f64
    var m = 0'f64
    var n = 0
    for index in 0 ..< count:
      let x32 = float32(input[3 + index]) / 16'f32
      let x = float64(x32)
      inc n
      let delta = x - mu
      mu = mu + delta / float64(n)
      let delta2 = x - mu
      m = m + delta * delta2
    mean64 = mu
    variance64 = m / float64(n)

  if variant < 2:
    case statistic
    of 0: return float64(mean32)
    of 1: return float64(variance32)
    else: return float64(float32(sqrt(float64(variance32))))
  case statistic
  of 0: return mean64
  of 1: return variance64
  else: return sqrt(variance64)
