import std/math

const MaxAngle = 1000.0

proc rotation_matrix*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                      output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rotation_matrix".} =
  if input.isNil or inputLen != csize_t(1): return -1
  let theta = input[0]
  if theta != theta or theta < -MaxAngle or theta > MaxAngle: return -1
  let cosine = cos(theta)
  let sine = sin(theta)
  let matrix = [cosine, -sine, sine, cosine]
  if output.isNil or outputCapacity < csize_t(4): return -2
  for index in 0 ..< 4:
    output[index] = matrix[index]
  4
