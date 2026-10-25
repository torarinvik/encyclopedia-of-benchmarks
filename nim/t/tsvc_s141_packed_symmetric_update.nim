const MaxN = 16
const MaxTriangle = MaxN * (MaxN + 1) div 2
const MaxInputLength = 2 + MaxTriangle + MaxN * MaxN
const MaxValue = 1_000_000'i64
const MaxRounds = 32

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc boundedValue(value: int64): bool =
  value >= -MaxValue and value <= MaxValue

proc tsvc_s141_packed_symmetric_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s141_packed_symmetric_update".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let rounds = input[1]
  if nValue < 1 or nValue > MaxN or rounds < 1 or rounds > MaxRounds: return -1
  let n = int(nValue)
  let triangle = n * (n + 1) div 2
  let matrixStart = 2 + triangle
  if int(length) != matrixStart + n * n: return -1

  var packed: array[MaxTriangle, int64]
  for p in 0 ..< triangle:
    packed[p] = input[2 + p]
    if not boundedValue(packed[p]): return -1
  for p in 0 ..< n * n:
    if not boundedValue(input[matrixStart + p]): return -1
  if output == nil or outputCapacity < csize_t(8 * triangle): return -2

  for round in 0 ..< int(rounds):
    for i in 0 ..< n:
      for j in i ..< n:
        let k = j * (j + 1) div 2 + i
        packed[k] += input[matrixStart + j * n + i]
  for p in 0 ..< triangle:
    storeI64Le(output, 8 * p, packed[p])
  int64(triangle)
