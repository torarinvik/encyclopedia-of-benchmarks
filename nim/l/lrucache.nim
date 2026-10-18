## Run bounded Java/JavaScript LRU cache traces and return operation records.
proc putI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[index * 8 + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc lrucache*(input: ptr UncheckedArray[int64], inputLength: csize_t,
               output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
               {.cdecl, exportc: "lrucache".} =
  if input.isNil or inputLength < 2 or inputLength > 99: return -1
  let capacityValue = input[0]
  let operationCountValue = input[1]
  if capacityValue < 2 or capacityValue > 16 or operationCountValue < 0 or operationCountValue > 32: return -1
  let capacity = int(capacityValue)
  let operationCount = int(operationCountValue)
  if inputLength != csize_t(2 + 3 * operationCount): return -1

  var keys: array[16, int64]
  var cachedValues: array[16, int64]
  var seenPutKeys: array[32, int64]
  var operationRecords: array[96, int64]
  var used = 0
  var seenCount = 0

  for operation in 0..<operationCount:
    let opcode = input[2 + 3 * operation]
    let key = input[3 + 3 * operation]
    let value = input[4 + 3 * operation]
    if opcode != 0 and opcode != 1: return -1
    if key < 0 or key > 1_000_000: return -1
    var returnedValue: int64 = -1
    var evictedKey: int64 = -1
    var position = 0
    while position < used and keys[position] != key: inc position

    if opcode == 0:
      if value < 0 or value > 1_000_000: return -1
      for prior in 0..<seenCount:
        if seenPutKeys[prior] == key: return -1
      seenPutKeys[seenCount] = key
      inc seenCount
      if used == capacity:
        evictedKey = keys[0]
        for index in 1..<used:
          keys[index - 1] = keys[index]
          cachedValues[index - 1] = cachedValues[index]
        dec used
      keys[used] = key
      cachedValues[used] = value
      inc used
    else:
      if value != 0 or position == used: return -1
      returnedValue = cachedValues[position]
      for index in position + 1..<used:
        keys[index - 1] = keys[index]
        cachedValues[index - 1] = cachedValues[index]
      keys[used - 1] = key
      cachedValues[used - 1] = returnedValue

    operationRecords[3 * operation] = opcode
    operationRecords[3 * operation + 1] = returnedValue
    operationRecords[3 * operation + 2] = evictedKey

  var fields: array[130, int64]
  var wordCount = 0
  fields[wordCount] = operationCountValue
  inc wordCount
  for index in 0..<3 * operationCount:
    fields[wordCount] = operationRecords[index]
    inc wordCount
  fields[wordCount] = int64(used)
  inc wordCount
  for offset in 0..<used:
    let index = used - 1 - offset
    fields[wordCount] = keys[index]
    fields[wordCount + 1] = cachedValues[index]
    wordCount += 2

  let outputBytes = wordCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0..<wordCount:
    putI64Le(output, index, fields[index])
  int64(outputBytes)
