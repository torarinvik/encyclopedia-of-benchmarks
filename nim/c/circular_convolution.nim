type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc circular_convolution*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "circular_convolution".} =
  if values == nil or length < 4: return -1
  let rawALength = values[0]
  let rawBLength = values[1]
  if rawALength < 1 or rawALength > 8 or rawBLength < 1 or rawBLength > 8: return -1
  let aLength = int(rawALength)
  let bLength = int(rawBLength)
  if length != csize_t(2 + aLength + bLength): return -1
  for index in 0 ..< aLength + bLength:
    if values[2 + index] < -2 or values[2 + index] > 2: return -1
  let n = max(aLength, bLength)
  if output == nil or outputCapacity < csize_t(n): return -2

  for k in 0 ..< n:
    var sum = 0'i64
    for i in 0 ..< n:
      let bIndex = (k + n - i) mod n
      let aValue = if i < aLength: values[2 + i] else: 0'i64
      let bValue = if bIndex < bLength: values[2 + aLength + bIndex] else: 0'i64
      sum += aValue * bValue
    let encoded = if sum < 0: sum + 256 else: sum
    output[k] = uint8(encoded)
  int64(n)
