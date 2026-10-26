# Clean-room bounded residual profile; see package README and RIGHTS.md.
import std/math
const MaxSide = 5

proc asci_purple_smg2000_residual*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "asci_purple_smg2000_residual".} =
  if input.isNil or length < csize_t(19) or length > csize_t(253): return -1
  for q in 0 ..< 3:
    let v = input[q]
    if not v.isFinite or v != floor(v) or v < 2.0 or v > float64(MaxSide): return -1
  let nx = int(input[0]); let ny = int(input[1]); let nz = int(input[2])
  let cells = nx * ny * nz
  if length != csize_t(3 + 2 * cells): return -1
  for q in 3 ..< int(length):
    let v = input[q]
    if not v.isFinite or v != floor(v) or v < -1000.0 or v > 1000.0: return -1
  if output.isNil or capacity < csize_t(cells): return -2
  let strideI = ny * nz; let strideJ = nz
  for i in 0 ..< nx:
    for j in 0 ..< ny:
      for k in 0 ..< nz:
        let q = i * strideI + j * strideJ + k
        let x = int64(input[3 + q])
        var ax = 222'i64 * x
        if i > 0: ax -= int64(input[3 + q - strideI])
        if i + 1 < nx: ax -= int64(input[3 + q + strideI])
        if j > 0: ax -= 10'i64 * int64(input[3 + q - strideJ])
        if j + 1 < ny: ax -= 10'i64 * int64(input[3 + q + strideJ])
        if k > 0: ax -= 100'i64 * int64(input[3 + q - 1])
        if k + 1 < nz: ax -= 100'i64 * int64(input[3 + q + 1])
        let b = int64(input[3 + cells + q])
        output[q] = float64(10'i64 * b - ax) / 10.0
  int64(cells)
