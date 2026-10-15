proc popcount(valueIn: uint64): int =
  var value = valueIn
  while value != 0:
    result += int(value and 1'u64)
    value = value shr 1

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 0xFF'u64)

proc association*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "association".} =
  if input.isNil or length < 2 or input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 11: return -1
  let transactions = int(input[0])
  let items = int(input[1])
  if length != csize_t(2 + transactions): return -1
  let itemLimit = 1 shl items
  let validBits = int64(itemLimit - 1)
  for t in 0 ..< transactions:
    if input[2 + t] < 0 or input[2 + t] > validBits: return -1

  var frequent: array[2048, bool]
  var masks: array[2047, int64]
  var supports: array[2047, int64]
  var resultCount = 0
  for setSize in 1 .. items:
    for mask in 1 ..< itemLimit:
      if popcount(uint64(mask)) != setSize: continue
      if setSize > 1:
        var allSubsetsFrequent = true
        for bit in 0 ..< items:
          let bitMask = 1 shl bit
          if (mask and bitMask) != 0 and not frequent[mask xor bitMask]: allSubsetsFrequent = false
        if not allSubsetsFrequent: continue
      var support = 0'i64
      for t in 0 ..< transactions:
        if (int(input[2 + t]) and mask) == mask: inc support
      if support > 0:
        frequent[mask] = true
        masks[resultCount] = int64(mask)
        supports[resultCount] = support
        inc resultCount

  let required = resultCount * 16
  if capacity < csize_t(required) or (required > 0 and output.isNil): return -2
  for i in 0 ..< resultCount:
    putI64Le(output, i * 16, masks[i])
    putI64Le(output, i * 16 + 8, supports[i])
  int64(required)
