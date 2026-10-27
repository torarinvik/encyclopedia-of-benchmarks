const MaxN = 16
const MaxM = 120
const MaxD = 4
const MaxInput = 431

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc max_cut_gw_rounding*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "max_cut_gw_rounding".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]; let m64 = input[1]; let d64 = input[2]
  if n64 < 2 or n64 > MaxN or m64 < 0 or m64 > MaxM or d64 < 1 or d64 > MaxD or
      int64(length) != 3 + 3*m64 + n64*d64 + d64: return -1
  let n = int(n64); let m = int(m64); let d = int(d64)
  var edgeU, edgeV, edgeWeight: array[MaxM, int64]
  var previousU = -1'i64; var previousV = -1'i64
  for edge in 0..<m:
    let u = input[3 + 3*edge]; let v = input[4 + 3*edge]; let weight = input[5 + 3*edge]
    if u < 0 or v <= u or v >= n64 or weight < 1 or weight > 10000 or
        u < previousU or (u == previousU and v <= previousV): return -1
    previousU = u; previousV = v
    edgeU[edge] = u; edgeV[edge] = v; edgeWeight[edge] = weight
  let vectorOffset = 3 + 3*m
  var vectors: array[MaxN, array[MaxD, int64]]
  var normal: array[MaxD, int64]
  var commonNorm = 0'i64
  for vertex in 0..<n:
    var norm = 0'i64
    for axis in 0..<d:
      let coordinate = input[vectorOffset + vertex*d + axis]
      if coordinate < -100 or coordinate > 100: return -1
      vectors[vertex][axis] = coordinate
      norm += coordinate * coordinate
    if vertex == 0: commonNorm = norm
    elif norm != commonNorm: return -1
  if commonNorm == 0: return -1
  var hasNormal = false
  for axis in 0..<d:
    normal[axis] = input[vectorOffset + n*d + axis]
    if normal[axis] < -100 or normal[axis] > 100: return -1
    if normal[axis] != 0: hasNormal = true
  if not hasNormal: return -1
  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var side: array[MaxN, int64]
  for vertex in 0..<n:
    var projection = 0'i64
    for axis in 0..<d: projection += vectors[vertex][axis] * normal[axis]
    if projection > 0: side[vertex] = 1
  var cut = 0'i64
  for edge in 0..<m:
    if side[int(edgeU[edge])] != side[int(edgeV[edge])]: cut += edgeWeight[edge]
  storeI64LE(output, 0, cut)
  for vertex in 0..<n: storeI64LE(output, 8*(vertex+1), side[vertex])
  int64(outputBytes)
