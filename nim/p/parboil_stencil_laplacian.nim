import std/math

const MaxCells = 125

proc parboil_stencil_laplacian*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "parboil_stencil_laplacian".} =
  if input.isNil or length < csize_t(4) or length > csize_t(129): return -1
  let nxv = input[0]
  let nyv = input[1]
  let nzv = input[2]
  let stepsv = input[3]
  for value in [nxv, nyv, nzv, stepsv]:
    if not value.isFinite or value != floor(value): return -1
  if nxv < 3 or nxv > 5 or nyv < 3 or nyv > 5 or nzv < 3 or nzv > 5 or stepsv < 1 or stepsv > 4: return -1
  let nx = int(nxv)
  let ny = int(nyv)
  let nz = int(nzv)
  let steps = int(stepsv)
  let cells = nx * ny * nz
  if int(length) != 4 + cells: return -1
  for q in 0 ..< cells:
    let value = input[4 + q]
    if not value.isFinite or value < -8.0 or value > 8.0: return -1
  if output.isNil or capacity < csize_t(cells): return -2

  var a: array[MaxCells, float32]
  var b: array[MaxCells, float32]
  var staged: array[MaxCells, float64]
  for q in 0 ..< cells:
    a[q] = float32(input[4 + q])
    b[q] = a[q]
  let c0 = float32(1.0'f32 / 6.0'f32)
  let c1 = float32(float32(1.0'f32 / 6.0'f32) / 6.0'f32)
  for _ in 0 ..< steps:
    for i in 1 ..< nx - 1:
      for j in 1 ..< ny - 1:
        for k in 1 ..< nz - 1:
          let q = i + nx * (j + ny * k)
          var sum = float32(a[q + nx * ny] + a[q - nx * ny])
          sum = float32(sum + a[q + nx])
          sum = float32(sum + a[q - nx])
          sum = float32(sum + a[q + 1])
          sum = float32(sum + a[q - 1])
          let neighborTerm = float32(sum * c1)
          let centerTerm = float32(a[q] * c0)
          b[q] = float32(neighborTerm - centerTerm)
    for q in 0 ..< cells:
      let temp = a[q]
      a[q] = b[q]
      b[q] = temp
  for q in 0 ..< cells: staged[q] = float64(a[q])
  for q in 0 ..< cells: output[q] = staged[q]
  int64(cells)
