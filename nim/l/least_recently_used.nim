proc least_recently_used*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "least_recently_used".} =
  if input == nil or length < 2 or length > 66: return -1
  let capacityValue = input[0]
  let referenceCountValue = input[1]
  if capacityValue < 1 or capacityValue > 16 or referenceCountValue < 0 or referenceCountValue > 64: return -1
  let cacheCapacity = int(capacityValue)
  let references = int(referenceCountValue)
  if length != csize_t(2 + references): return -1
  for i in 0 ..< references:
    let key = input[2 + i]
    if key < -2_147_483_648'i64 or key > 2_147_483_647'i64: return -1

  var keys: array[16, int64]
  var count = 0
  for i in 0 ..< references:
    let key = input[2 + i]
    var found = count
    for j in 0 ..< count:
      if keys[j] == key:
        found = j
        break
    if found < count:
      var j = found
      while j + 1 < count:
        keys[j] = keys[j + 1]
        j += 1
      dec count
    elif count == cacheCapacity: dec count
    var j = count
    while j > 0:
      keys[j] = keys[j - 1]
      dec j
    keys[0] = key
    inc count

  let elements = count + 1
  let required = elements * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  var sizeBits = uint64(count)
  for byte in 0 ..< 8:
    output[byte] = uint8(sizeBits and 255)
    sizeBits = sizeBits shr 8
  for i in 0 ..< count:
    var bits = cast[uint64](keys[i])
    for byte in 0 ..< 8:
      output[(i + 1) * 8 + byte] = uint8(bits and 255)
      bits = bits shr 8
  int64(elements)
