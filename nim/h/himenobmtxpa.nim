import std/math

const MaxSide = 6

proc himenobmtxpa*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "himenobmtxpa".} =
  if input.isNil or length != csize_t(4): return -1
  var dimensions: array[4, int]
  for q in 0 ..< 4:
    let value = input[q]
    if not value.isFinite or value != floor(value): return -1
    if q < 3:
      if value < 2.0 or value > float64(MaxSide): return -1
    else:
      if value < 1.0 or value > 4.0: return -1
    dimensions[q] = int(value)
  let nx = dimensions[0]
  let ny = dimensions[1]
  let nz = dimensions[2]
  let iterations = dimensions[3]
  if output.isNil or capacity < csize_t(1): return -2

  var p: array[216, float32]
  var work: array[216, float32]
  let a3 = 1'f32 / 6'f32
  let omega = 0.8'f32
  let denominator = float32((nx - 1) * (nx - 1))
  for i in 0 ..< nx:
    for j in 0 ..< ny:
      for k in 0 ..< nz:
        let q = i * ny * nz + j * nz + k
        p[q] = float32(i * i) / denominator
  var gosa = 0'f32
  for iteration in 0 ..< iterations:
    gosa = 0'f32
    for i in 1 ..< nx-1:
      for j in 1 ..< ny-1:
        for k in 1 ..< nz-1:
          let q = i * ny * nz + j * nz + k
          var s0 = p[q + ny * nz] + p[q + nz] + p[q + 1]
          s0 = s0 + p[q - ny * nz] + p[q - nz] + p[q - 1]
          let ss = s0 * a3 - p[q]
          gosa = gosa + ss * ss
          work[q] = p[q] + omega * ss
    for i in 1 ..< nx-1:
      for j in 1 ..< ny-1:
        for k in 1 ..< nz-1:
          let q = i * ny * nz + j * nz + k
          p[q] = work[q]
  output[0] = float64(gosa)
  1
