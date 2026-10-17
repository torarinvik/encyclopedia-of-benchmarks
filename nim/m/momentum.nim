const MaxLength = 64
const Iterations = 100
const LearningRate = 0.01
const Beta = 0.9

proc momentum*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "momentum".} =
  if input == nil or length == 0 or length > csize_t(MaxLength): return -1
  let count = int(length)
  var values: array[MaxLength, float64]
  var velocity: array[MaxLength, float64]
  var gradient: array[MaxLength, float64]
  for index in 0 ..< count:
    let value = input[index]
    if value != value or value < -1_000_000.0 or value > 1_000_000.0: return -1
    values[index] = value
  if output == nil or outputCapacity < length: return -2

  for _ in 0 ..< Iterations:
    for index in 0 ..< count: gradient[index] = 2.0 * values[index]
    for index in 0 ..< count:
      velocity[index] = Beta * velocity[index] + gradient[index]
      values[index] -= LearningRate * velocity[index]
  for index in 0 ..< count: output[index] = values[index]
  int64(count)
