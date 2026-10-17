const MaxN = 16
const MaxInputWords = 3 + MaxN * MaxN
const MaxParseableInputWords = MaxInputWords + 1
const MaxOutputBytes = 8 * MaxN * MaxN

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc max_pooling*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "max_pooling".} =
  if input == nil or length < 3 or length > csize_t(MaxParseableInputWords): return -1
  let nRaw = input[0]
  let sizeRaw = input[1]
  let strideRaw = input[2]
  if nRaw < 1 or nRaw > MaxN or sizeRaw < 1 or sizeRaw > nRaw or strideRaw < 1 or strideRaw > MaxN: return -1
  let n = int(nRaw)
  let size = int(sizeRaw)
  let stride = int(strideRaw)
  if int(length) != 3 + n * n: return -1
  for i in 0 ..< n * n:
    if input[3 + i] < -1_000_000 or input[3 + i] > 1_000_000: return -1
  let outSide = (n - size) div stride + 1
  let outputCount = outSide * outSide
  let bytes = outputCount * 8
  if output == nil or capacity < csize_t(bytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  var position = 0
  for row in 0 ..< outSide:
    for col in 0 ..< outSide:
      let startRow = row * stride
      let startCol = col * stride
      var maximum = input[3 + startRow * n + startCol]
      for r in 0 ..< size:
        for c in 0 ..< size:
          let value = input[3 + (startRow + r) * n + startCol + c]
          if value > maximum: maximum = value
      putF64Le(addr buffer[0], position, float64(maximum))
      position += 8
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
