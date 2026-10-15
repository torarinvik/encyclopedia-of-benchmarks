const MaxItems = 64
const BytesPerTriplet = 12

type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc writeI32Le(output: ByteArray, offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc enumerate(values: I64Array, length: int, output: ByteArray, writeOutput: bool): int =
  var count = 0
  var hasLast = false
  var lastA, lastB, lastC: int64
  for i in 0 ..< length:
    if i + 2 >= length: break
    for j in i + 1 ..< length:
      if j + 1 >= length: break
      for k in j + 1 ..< length:
        if values[i] + values[j] + values[k] != 0: continue
        if hasLast and values[i] == lastA and values[j] == lastB and values[k] == lastC: continue
        if writeOutput:
          let offset = count * BytesPerTriplet
          writeI32Le(output, offset, values[i])
          writeI32Le(output, offset + 4, values[j])
          writeI32Le(output, offset + 8, values[k])
        lastA = values[i]
        lastB = values[j]
        lastC = values[k]
        hasLast = true
        inc count
  count

proc find_triplets_with_0_sum*(input: I64Array, length: csize_t, output: ByteArray, outputCapacity: csize_t): int64
    {.cdecl, exportc: "find_triplets_with_0_sum".} =
  if length > csize_t(MaxItems) or (length > 0 and input.isNil): return -1
  let count = int(length)
  var values: array[MaxItems, int64]
  for i in 0 ..< count:
    if input[i] < -100_000 or input[i] > 100_000: return -1
    values[i] = input[i]
  for i in 1 ..< count:
    let key = values[i]
    var j = i
    while j > 0 and values[j - 1] > key:
      values[j] = values[j - 1]
      dec j
    values[j] = key
  let resultCount = enumerate(cast[I64Array](addr values[0]), count, output, false)
  if resultCount == 0: return 0
  let needed = resultCount * BytesPerTriplet
  if output.isNil or outputCapacity < csize_t(needed): return -2
  int64(enumerate(cast[I64Array](addr values[0]), count, output, true))
