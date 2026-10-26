const MaxK = 8
const MaxItems = 64
const MaxInput = 66

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc misra_gries_summaries*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "misra_gries_summaries".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let k64 = input[0]
  let count64 = input[1]
  if k64 < 1 or k64 > int64(MaxK) or count64 < 0 or count64 > int64(MaxItems) or
      int64(length) != 2 + count64: return -1
  let k = int(k64)
  let count = int(count64)
  var items: array[MaxK, int64]
  var counts: array[MaxK, int64]
  for slot in 0..<k: items[slot] = -1
  for index in 0..<count:
    let item = input[index + 2]
    if item < 0 or item > 15: return -1
    var slot = 0
    while slot < k and items[slot] != item: inc slot
    if slot < k:
      inc counts[slot]
    else:
      slot = 0
      while slot < k and counts[slot] != 0: inc slot
      if slot < k:
        items[slot] = item
        counts[slot] = 1
      else:
        for indexSlot in 0..<k:
          dec counts[indexSlot]
          if counts[indexSlot] == 0: items[indexSlot] = -1
  var used = 0
  for slot in 0..<k:
    if counts[slot] > 0: inc used
  let outputBytes = 8 * (1 + 2 * used)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var orderedItems: array[MaxK, int64]
  var orderedCounts: array[MaxK, int64]
  var at = 0
  for slot in 0..<k:
    if counts[slot] > 0:
      var position = at
      while position > 0 and orderedItems[position - 1] > items[slot]:
        orderedItems[position] = orderedItems[position - 1]
        orderedCounts[position] = orderedCounts[position - 1]
        dec position
      orderedItems[position] = items[slot]
      orderedCounts[position] = counts[slot]
      inc at
  storeI64LE(output, 0, int64(used))
  for index in 0..<used:
    storeI64LE(output, 8 * (1 + 2 * index), orderedItems[index])
    storeI64LE(output, 8 * (2 + 2 * index), orderedCounts[index])
  int64(outputBytes)
