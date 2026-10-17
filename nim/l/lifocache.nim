proc lifocache*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lifocache".} =
  if input == nil or length < 2 or length > 194: return -1
  let capacityValue = input[0]
  let operationCountValue = input[1]
  if capacityValue < 1 or capacityValue > 16 or operationCountValue < 1 or operationCountValue > 64: return -1
  let cacheCapacity = int(capacityValue)
  let operations = int(operationCountValue)
  if length != csize_t(2 + 3 * operations): return -1
  for i in 0 ..< operations:
    let op = input[2 + 3 * i]
    let key = input[3 + 3 * i]
    let value = input[4 + 3 * i]
    if op < 0 or op > 6: return -1
    if op <= 2:
      if key < -2_147_483_648'i64 or key > 2_147_483_647'i64: return -1
      if op == 0:
        if value < -2_147_483_648'i64 or value > 2_147_483_647'i64: return -1
      elif value != 0: return -1
    elif key != 0 or value != 0: return -1

  let required = operations * 16
  if output == nil or outputCapacity < csize_t(required): return -2
  var keys: array[16, int64]
  var values: array[16, int64]
  var count = 0
  var hits = 0'i64
  var misses = 0'i64
  for i in 0 ..< operations:
    let op = input[2 + 3 * i]
    let key = input[3 + 3 * i]
    let value = input[4 + 3 * i]
    var first = 0'i64
    var second = 0'i64
    if op == 0:
      var found = count
      for j in 0 ..< count:
        if keys[j] == key:
          found = j
          break
      if found < count:
        for j in found ..< count - 1:
          keys[j] = keys[j + 1]
          values[j] = values[j + 1]
        dec count
      if count == cacheCapacity: dec count
      keys[count] = key
      values[count] = value
      inc count
      first = 1
    elif op == 1:
      var found = count
      for j in 0 ..< count:
        if keys[j] == key:
          found = j
          break
      if found < count:
        inc hits
        first = 1
        second = values[found]
      else: inc misses
    elif op == 2:
      var found = count
      for j in 0 ..< count:
        if keys[j] == key:
          found = j
          break
      if found < count:
        first = 1
        second = values[found]
        for j in found ..< count - 1:
          keys[j] = keys[j + 1]
          values[j] = values[j + 1]
        dec count
    elif op == 3: first = int64(count)
    elif op == 4: first = hits
    elif op == 5: first = misses
    else:
      count = 0
      hits = 0
      misses = 0
      first = 1
    var firstBits = cast[uint64](first)
    var secondBits = cast[uint64](second)
    for byte in 0 ..< 8:
      output[i * 16 + byte] = uint8(firstBits and 255)
      output[i * 16 + 8 + byte] = uint8(secondBits and 255)
      firstBits = firstBits shr 8
      secondBits = secondBits shr 8
  int64(2 * operations)
