const InvalidResult = -1.0e300

proc schur_complement*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "schur_complement".} =
  if input.isNil or length != 6: return InvalidResult
  let a00 = input[0]
  let a01 = input[1]
  let a11 = input[2]
  let b0 = input[3]
  let b1 = input[4]
  let c00 = input[5]
  if a00 < -8 or a00 > 8 or a01 < -8 or a01 > 8 or a11 < -8 or a11 > 8 or
     b0 < -100 or b0 > 100 or b1 < -100 or b1 > 100 or c00 < -100 or c00 > 100: return InvalidResult
  let determinant = a00 * a11 - a01 * a01
  if determinant == 0: return InvalidResult
  let inv00 = float64(a11) / float64(determinant)
  let inv01 = -float64(a01) / float64(determinant)
  let inv10 = -float64(a01) / float64(determinant)
  let inv11 = float64(a00) / float64(determinant)
  let left0 = float64(b0) * inv00 + float64(b1) * inv10
  let left1 = float64(b0) * inv01 + float64(b1) * inv11
  let quadratic = left0 * float64(b0) + left1 * float64(b1)
  float64(c00) - quadratic
