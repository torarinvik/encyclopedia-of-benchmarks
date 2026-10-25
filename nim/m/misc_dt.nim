import std/math

const MaxIterations = 128
const MaxVectorSize = 64

proc misc_dt*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "misc_dt".} =
  if input.isNil or inputLength != csize_t(2): return -1
  let requestedIterations = input[0]
  let requestedSize = input[1]
  if requestedIterations != requestedIterations or requestedIterations < 1.0 or
      requestedIterations > float64(MaxIterations) or float64(int64(requestedIterations)) != requestedIterations: return -1
  if requestedSize != requestedSize or requestedSize < 1.0 or
      requestedSize > float64(MaxVectorSize) or float64(int64(requestedSize)) != requestedSize: return -1
  let iterations = int64(requestedIterations)
  let size = int(requestedSize)
  if output.isNil or outputCapacity < csize_t(size): return -2

  var numerator: array[MaxVectorSize, float64]
  var denominator: array[MaxVectorSize, float64]
  for index in 0 ..< size:
    let cosine = float32(cos(float64(size - index)))
    let sine = float32(sin(float64(index)))
    numerator[index] = 1.0000001 * float64(cosine)
    denominator[index] = 1.0 + 1e-10 * float64(sine)
  for _ in 0 ..< int(iterations):
    for index in 0 ..< size:
      numerator[index] = numerator[index] / denominator[index]
  for index in 0 ..< size: output[index] = numerator[index]
  int64(size)
