const MatrixSize = 10
const CellCount = MatrixSize * MatrixSize
const MaxIterations = 4096'i64
const MaxOutputBytes = 23

proc appendInteger(buffer: var array[MaxOutputBytes, uint8], used: var int, value: int32) =
  var remaining = value
  var reversed: array[10, uint8]
  var count = 0
  while true:
    reversed[count] = uint8(48 + remaining mod 10)
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reversed[count]
    inc used

proc shootout_matrix*(iterationCount: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "shootout_matrix".} =
  if iterationCount < 0 or iterationCount > MaxIterations: return -1

  var left, right, product: array[CellCount, int32]
  for index in 0 ..< CellCount:
    left[index] = int32(index + 1)
    right[index] = int32(index + 1)
    product[index] = int32(index + 1)

  for _ in 0 ..< int(iterationCount):
    for row in 0 ..< MatrixSize:
      for column in 0 ..< MatrixSize:
        var value = 0'i32
        for inner in 0 ..< MatrixSize:
          value += left[row * MatrixSize + inner] * right[inner * MatrixSize + column]
        product[row * MatrixSize + column] = value

  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  appendInteger(staged, used, product[0])
  staged[used] = uint8(ord(' ')); inc used
  appendInteger(staged, used, product[23])
  staged[used] = uint8(ord(' ')); inc used
  appendInteger(staged, used, product[32])
  staged[used] = uint8(ord(' ')); inc used
  appendInteger(staged, used, product[44])
  staged[used] = 10'u8; inc used

  if output.isNil or outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
