const MaxIterations = 256'i64
const VectorLength = 2048

proc misc_fp_convert*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "misc_fp_convert".} =
  if input.isNil or inputLength != csize_t(1): return -1
  let requested = input[0]
  if requested != requested or requested < 1.0 or requested > float64(MaxIterations): return -1
  if float64(int64(requested)) != requested: return -1
  if output.isNil or outputCapacity < csize_t(1): return -2

  let iterations = int64(requested)
  var x: array[VectorLength, float32]
  var y: array[VectorLength, float32]
  var a = 0'f32
  var b = 1'f32
  var total = 0.0
  for iteration in 0'i64 ..< iterations:
    if iteration mod 10 != 0:
      a = 0'f32
      b = 1'f32
    else:
      a += 0.1'f32
      b += 0.2'f32
    for index in 0 ..< VectorLength:
      x[index] = a + float32(index)
      y[index] = b + float32(index)
    var accumulator = 0.0
    for index in 0 ..< VectorLength:
      accumulator += float64(x[index]) * float64(y[index])
    total += accumulator
  output[0] = total
  1
