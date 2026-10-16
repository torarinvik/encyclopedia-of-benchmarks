const
  MaxVertices = 32
  MaxEdges = MaxVertices * (MaxVertices - 1)
  MaxInputLength = 2 + 2 * MaxEdges
  MaxCells = MaxVertices * MaxVertices

type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc transitive_closure_reflexive_matrix*(input: I64Input, length: csize_t,
    output: U8Output, capacity: csize_t): int64 {.cdecl, exportc: "transitive_closure_reflexive_matrix".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  if n64 < 1 or n64 > int64(MaxVertices): return -1
  let n = int(n64)
  let m64 = input[1]
  if m64 < 0 or m64 > int64(n * (n - 1)): return -1
  let m = int(m64)
  if length != csize_t(2 + 2 * m): return -1

  var reach: array[MaxCells, int64]
  for i in 0..<n: reach[i * n + i] = 1
  for edge in 0..<m:
    let from64 = input[2 + 2 * edge]
    let to64 = input[3 + 2 * edge]
    if from64 < 0 or from64 >= n64 or to64 < 0 or to64 >= n64 or from64 == to64: return -1
    let from = int(from64)
    let to = int(to64)
    if reach[from * n + to] != 0: return -1
    reach[from * n + to] = 1

  for k in 0..<n:
    for i in 0..<n:
      if reach[i * n + k] == 1:
        for j in 0..<n:
          if reach[k * n + j] == 1: reach[i * n + j] = 1

  let outputBytes = n * n * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for index in 0..<n * n: putI64Le(output, index * 8, reach[index])
  int64(outputBytes)
