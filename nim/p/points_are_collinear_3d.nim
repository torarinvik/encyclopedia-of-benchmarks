## Check whether three bounded integer points lie on one 3D line.
proc points_are_collinear_3d*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "points_are_collinear_3d".} =
  if length != 9 or values.isNil: return -1
  for index in 0 ..< 9:
    if values[index] < -10000 or values[index] > 10000: return -1

  let abx = values[3] - values[0]
  let aby = values[4] - values[1]
  let abz = values[5] - values[2]
  let acx = values[6] - values[0]
  let acy = values[7] - values[1]
  let acz = values[8] - values[2]
  let crossX = aby * acz - abz * acy
  let crossY = abz * acx - abx * acz
  let crossZ = abx * acy - aby * acx
  if crossX == 0 and crossY == 0 and crossZ == 0: 1 else: 0
