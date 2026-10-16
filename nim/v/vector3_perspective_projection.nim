const InputLimit = 1_000_000.0
const DenominatorFloor = 0.000001
const OutputLimit = 1.0e25

proc vector3_perspective_projection*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                                     output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "vector3_perspective_projection".} =
  if input.isNil or inputLen != 5: return -1
  for i in 0..<5:
    if input[i] != input[i] or input[i] < -InputLimit or input[i] > InputLimit: return -1
  let denominator = input[2] + input[4]
  if denominator > -DenominatorFloor and denominator < DenominatorFloor: return -1
  let x = ((input[0] * input[4]) / denominator) * input[3]
  let y = ((input[1] * input[4]) / denominator) * input[3]
  if x != x or y != y or x < -OutputLimit or x > OutputLimit or y < -OutputLimit or y > OutputLimit:
    return -1
  if output.isNil or outputCapacity < 2: return -2
  output[0] = x
  output[1] = y
  2
