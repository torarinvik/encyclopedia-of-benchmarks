proc list_array*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "list_array".} =
  if input == nil or length < 2 or length > 130: return -1
  let capacityValue = input[0]
  let operationCountValue = input[1]
  if capacityValue < 1 or capacityValue > 16 or operationCountValue < 1 or operationCountValue > 64: return -1
  let capacity = int(capacityValue)
  let operations = int(operationCountValue)
  if length != csize_t(2 + 2 * operations): return -1

  var opcodes: array[64, int64]
  var arguments: array[64, int64]
  var sorted = false
  for i in 0 ..< operations:
    let opcode = input[2 + 2 * i]
    let argument = input[3 + 2 * i]
    if opcode == 0:
      if sorted or argument < 0: return -1
    elif opcode == 1:
      if sorted or argument != 0: return -1
      sorted = true
    elif opcode == 2 or opcode == 3:
      if not sorted or argument < 0: return -1
    else: return -1
    opcodes[i] = opcode
    arguments[i] = argument
  if not sorted: return -1

  var items: array[16, uint64]
  var results: array[64, int64]
  var outputWords: array[65, int64]
  var count = 0
  var resultCount = 0
  for i in 0 ..< operations:
    let opcode = opcodes[i]
    let argument = arguments[i]
    if opcode == 0:
      if count == capacity: return -1
      items[count] = uint64(argument)
      inc count
    elif opcode == 1:
      for a in 0 ..< count:
        var minimum = a
        for b in a + 1 ..< count:
          if items[b] < items[minimum]: minimum = b
        swap(items[minimum], items[a])
    else:
      if count == 0 or uint64(argument) < items[0]: return -1
      if opcode == 3 and count >= capacity: return -1
      var first = 0
      var last = count - 1
      var position = -1'i64
      while first <= last:
        let middle = (first + last) div 2
        let value = items[middle]
        if value == uint64(argument):
          position = int64(middle)
          break
        elif uint64(argument) < value: last = middle - 1
        else: first = middle + 1
      results[resultCount] = position
      inc resultCount
      if opcode == 3 and position >= 0:
        for j in int(position) ..< count: items[j] = items[j + 1]
        dec count

  var wordCount = 0
  outputWords[wordCount] = int64(resultCount)
  inc wordCount
  for i in 0 ..< resultCount:
    outputWords[wordCount] = results[i]
    inc wordCount
  outputWords[wordCount] = int64(count)
  inc wordCount
  for i in 0 ..< count:
    outputWords[wordCount] = int64(items[i])
    inc wordCount
  let required = wordCount * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  for i in 0 ..< wordCount:
    var bits = cast[uint64](outputWords[i])
    for byte in 0 ..< 8:
      output[i * 8 + byte] = uint8(bits and 255)
      bits = bits shr 8
  int64(required)
