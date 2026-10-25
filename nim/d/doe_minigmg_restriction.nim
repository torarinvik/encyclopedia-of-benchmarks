proc doe_minigmg_restriction*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "doe_minigmg_restriction".} =
  if values == nil or length < 11 or length > 515: return -1.0e300
  let nxRaw = values[0]
  let nyRaw = values[1]
  let nzRaw = values[2]
  if nxRaw < 2 or nxRaw > 8 or nxRaw mod 2 != 0: return -1.0e300
  if nyRaw < 2 or nyRaw > 8 or nyRaw mod 2 != 0: return -1.0e300
  if nzRaw < 2 or nzRaw > 8 or nzRaw mod 2 != 0: return -1.0e300

  let nx = int(nxRaw)
  let ny = int(nyRaw)
  let nz = int(nzRaw)
  let cells = nx * ny * nz
  if length != csize_t(3 + cells): return -1.0e300
  for q in 0 ..< cells:
    if values[3 + q] < -32768 or values[3 + q] > 32767: return -1.0e300

  let coarseNx = nx div 2
  let coarseNy = ny div 2
  let coarseNz = nz div 2
  let plane = nx * ny
  var checksum = 0.0
  var coarseIndex = 0
  for k in 0 ..< coarseNz:
    for j in 0 ..< coarseNy:
      for i in 0 ..< coarseNx:
        let base = 3 + 2 * i + 2 * j * nx + 2 * k * plane
        let sum = float64(values[base]) + float64(values[base + 1]) +
          float64(values[base + nx]) + float64(values[base + nx + 1]) +
          float64(values[base + plane]) + float64(values[base + plane + 1]) +
          float64(values[base + plane + nx]) + float64(values[base + plane + nx + 1])
        let restricted = sum * 0.125
        let weight = float64(coarseIndex + 1)
        checksum += weight * restricted * restricted
        inc coarseIndex
  checksum
