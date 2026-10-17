const MaxN = 8
const MaxInputWords = 1 + MaxN * MaxN
const MaxOutputBytes = 4 * (1 + MaxN * MaxN)

proc searchPath(input: ptr UncheckedArray[int32], path: ptr UncheckedArray[int32], n, row, col: int): bool =
  let index = row * n + col
  path[index] = 1
  if row == n - 1 and col == n - 1: return true
  if col + 1 < n and input[1 + index + 1] == 1 and searchPath(input, path, n, row, col + 1): return true
  if row + 1 < n and input[1 + index + n] == 1 and searchPath(input, path, n, row + 1, col): return true
  path[index] = 0
  false

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc rat_maze*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rat_maze".} =
  if input == nil or length < 2 or length > csize_t(MaxInputWords): return -1
  let nRaw = input[0]
  if nRaw < 1 or nRaw > MaxN: return -1
  let n = int(nRaw)
  let cells = n * n
  if int(length) != 1 + cells or input[1] != 1: return -1
  for i in 0 ..< cells:
    if input[1 + i] < 0 or input[1 + i] > 1: return -1
  var path: array[MaxN * MaxN, int32]
  let found = searchPath(input, cast[ptr UncheckedArray[int32]](addr path[0]), n, 0, 0)
  let wordCount = if found: 1 + cells else: 1
  let bytes = wordCount * 4
  if output == nil or capacity < csize_t(bytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  putI32Le(addr buffer[0], 0, if found: 1'i32 else: 0'i32)
  if found:
    for i in 0 ..< cells: putI32Le(addr buffer[0], (i + 1) * 4, path[i])
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
