import std/math

const MaxInputLength = 5

proc exactInteger(value: float64, low, high: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < float64(low) or value > float64(high):
    return false
  float64(int64(value)) == value

proc integrand(id: int, x: float64): float64 =
  case id
  of 0: exp(x)
  of 1: x*x*x*x*x
  of 2: 1.0/(1.0+x*x)
  else: cos(x)

proc romberg(id: int, a, b: float64, levels: int): float64 =
  if a == b: return 0.0
  var previous: array[9, float64]
  previous[0] = (b-a)*(integrand(id,a)+integrand(id,b))*0.5
  for level in 1 .. levels:
    let intervalCount = 1 shl level
    let spacing = (b-a)/float64(intervalCount)
    var added = 0.0
    for index in countup(1, intervalCount-1, 2):
      added += integrand(id, a+float64(index)*spacing)
    var current: array[9, float64]
    current[0] = previous[0]*0.5+spacing*added
    var factor = 4.0
    for order in 1 .. level:
      current[order] = current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0)
      factor *= 4.0
    previous = current
  previous[levels]

proc romberg_integration*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "romberg_integration".} =
  if input == nil or inputLength != 4 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0],0,3) or not exactInteger(input[1],-1_000_000,1_000_000) or
      not exactInteger(input[2],-1_000_000,1_000_000) or not exactInteger(input[3],3,8): return -1
  let id = int(input[0])
  let aMicro = int64(input[1])
  let bMicro = int64(input[2])
  let levels = int(input[3])
  if aMicro > bMicro: return -1
  if output == nil or outputCapacity < 1: return -2
  let result = romberg(id,float64(aMicro)/1_000_000.0,float64(bMicro)/1_000_000.0,levels)
  if classify(result) in {fcNan, fcInf, fcNegInf}: return -1
  output[0] = result
  1
