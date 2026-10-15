const MaxLength = 128

proc gcdPositive(a, b: int64): int64 =
  var left = a
  var right = b
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc push(value: int64, items: var array[MaxLength, int64],
    aggregates: var array[MaxLength, int64], length: var int) =
  items[length] = value
  aggregates[length] = if length == 0: value else: gcdPositive(aggregates[length - 1], value)
  inc length

proc shortest_coprime_segment*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "shortest_coprime_segment".} =
  if length > MaxLength or (length != 0 and input == nil): return -1
  let count = int(length)
  for i in 0 ..< count:
    if input[i] < 1 or input[i] > 1000: return -1
  var front, frontGcd, back, backGcd: array[MaxLength, int64]
  var frontLength = 0
  var backLength = 0
  var left = 0
  var bestStart = 0
  var bestLength = count + 1
  for right in 0 ..< count:
    push(input[right], back, backGcd, backLength)
    var windowGcd = gcdPositive(
      (if frontLength > 0: frontGcd[frontLength - 1] else: 0),
      (if backLength > 0: backGcd[backLength - 1] else: 0))
    while windowGcd == 1:
      let currentLength = right - left + 1
      if currentLength < bestLength:
        bestLength = currentLength
        bestStart = left
      if frontLength == 0:
        while backLength > 0:
          dec backLength
          let value = back[backLength]
          push(value, front, frontGcd, frontLength)
      dec frontLength
      inc left
      windowGcd = gcdPositive(
        (if frontLength > 0: frontGcd[frontLength - 1] else: 0),
        (if backLength > 0: backGcd[backLength - 1] else: 0))
  if bestLength > count: return 0
  let byteCount = bestLength * 8
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for i in 0 ..< bestLength:
    let bits = uint64(input[bestStart + i])
    for byte in 0 ..< 8:
      output[8 * i + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(byteCount)
