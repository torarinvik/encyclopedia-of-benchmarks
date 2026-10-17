import std/math

proc piecewise_without_inbuilt*(input: ptr UncheckedArray[float64], inputLen: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "piecewise_without_inbuilt".} =
  if input == nil or inputLen != csize_t(1): return -1
  let x = input[0]
  if classify(x) in {fcNan, fcInf, fcNegInf} or x < -10.0 or x > 10.0: return -1

  var y = 1.0
  if x <= -0.5:
    y = 0.0
  elif x < 0.5:
    y = x

  if output == nil or outputCapacity < csize_t(1): return -2
  output[0] = y
  1
