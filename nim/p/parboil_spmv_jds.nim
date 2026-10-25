import std/strutils

const MaxN = 8
const MaxZ = 64
const MaxOut = 36

proc decode(v: int64): float32 = float32(v) / 1_000_000'f32
proc put32(outp: ptr UncheckedArray[uint8], p: int, x: uint32) =
  for b in 0 .. 3: outp[p+b] = uint8((x shr (8*b)) and 255)

proc parboil_spmv_jds(input: ptr UncheckedArray[int64], inputLength: int,
                      output: ptr UncheckedArray[uint8], outputCapacity: int): int64 {.exportc.} =
  if input.isNil or inputLength < 3 or inputLength > 164: return -1
  if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8 or input[2] < 1 or input[2] > 64: return -1
  let n = int(input[0]); let d = int(input[1]); let z = int(input[2])
  if inputLength != 4 + 3*n + d + 2*z: return -1
  var row, perm, ptrs: array[9, int64]
  var col, dat: array[64, int64]
  var vec: array[8, int64]
  var p = 3
  for i in 0 ..< n:
    if input[p] < 0 or input[p] > int64(d): return -1
    row[i] = input[p]; inc p
  if row[0] != int64(d): return -1
  for i in 1 ..< n:
    if row[i] > row[i-1]: return -1
  for i in 0 ..< n: perm[i] = input[p]; inc p
  for i in 0 ..< n:
    if perm[i] < 0 or perm[i] >= int64(n): return -1
    for j in 0 ..< i:
      if perm[i] == perm[j]: return -1
  for k in 0 .. d: ptrs[k] = input[p]; inc p
  for j in 0 ..< z: col[j] = input[p]; inc p
  for j in 0 ..< z: dat[j] = input[p]; inc p
  for i in 0 ..< n: vec[i] = input[p]; inc p
  if ptrs[0] != 0: return -1
  var off = 0
  for k in 0 ..< d:
    var count = 0
    for i in 0 ..< n:
      if row[i] > int64(k): inc count
    off += count
    if ptrs[k+1] != int64(off): return -1
  if off != z: return -1
  for j in 0 ..< z:
    if col[j] < 0 or col[j] >= int64(n) or dat[j] < -1_000_000 or dat[j] > 1_000_000: return -1
  for i in 0 ..< n:
    if vec[i] < -1_000_000 or vec[i] > 1_000_000: return -1
  if output.isNil or outputCapacity < 4 + 4*n: return -2
  var y: array[8, float32]
  var staged: array[MaxOut, uint8]
  for i in 0 ..< n:
    var acc = 0'f32
    for k in 0 ..< int(row[i]):
      let j = int(ptrs[k]) + i
      let product = decode(dat[j]) * decode(vec[int(col[j])])
      acc = acc + product
    y[int(perm[i])] = acc
  put32(addr staged[0], 0, uint32(n))
  for i in 0 ..< n: put32(addr staged[0], 4+4*i, cast[uint32](y[i]))
  for i in 0 ..< 4+4*n: output[i] = staged[i]
  int64(4+4*n)
