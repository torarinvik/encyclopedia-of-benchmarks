proc keyPriorityQueue*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "key_priority_queue".} =
  if input == nil or length < 1 or length > 98: return -1
  if input[0] < 0 or input[0] > 32: return -1
  var keys: array[32, int64]
  var priorities: array[32, int64]
  var answers: array[32, int64]
  var heapSize = 0
  var answerCount = 0
  var position = 1
  proc findKey(key: int64): int =
    for i in 0 ..< heapSize:
      if keys[i] == key: return i
    heapSize
  proc swapItems(a, b: int) =
    swap(keys[a], keys[b]); swap(priorities[a], priorities[b])
  proc shiftUp(start: int) =
    var i = start
    while i > 0:
      let parent = (i - 1) div 2
      if priorities[parent] <= priorities[i]: break
      swapItems(parent, i); i = parent
  proc shiftDown(start: int) =
    var i = start
    while 2 * i + 1 < heapSize:
      let left = 2 * i + 1
      let right = left + 1
      var child = -1
      if priorities[left] < priorities[i] and (right >= heapSize or priorities[left] < priorities[right]): child = left
      elif right < heapSize and priorities[right] < priorities[i]: child = right
      else: break
      swapItems(i, child); i = child
  for operationIndex in 0 ..< int(input[0]):
    if position >= int(length): return -1
    let operation = input[position]
    if operation == 0 or operation == 1:
      if position + 2 >= int(length): return -1
      let key = input[position + 1]
      let priority = input[position + 2]
      if key < -1_000_000_000'i64 or key > 1_000_000_000'i64 or priority < -1_000_000_000'i64 or priority > 1_000_000_000'i64: return -1
      position += 3
      let found = findKey(key)
      if operation == 0:
        if found != heapSize: return -1
        keys[heapSize] = key; priorities[heapSize] = priority
        shiftUp(heapSize); inc heapSize
      elif found == heapSize:
        keys[heapSize] = key; priorities[heapSize] = priority
        shiftUp(heapSize); inc heapSize
      else:
        priorities[found] = priority
        if found > 0 and priorities[(found - 1) div 2] > priority: shiftUp(found)
        else:
          let left = 2 * found + 1; let right = left + 1
          if (left < heapSize and priorities[left] < priority) or (right < heapSize and priorities[right] < priority): shiftDown(found)
    elif operation == 2:
      inc position
      if heapSize == 0: return -1
      swapItems(0, heapSize - 1)
      dec heapSize
      answers[answerCount] = keys[heapSize]; inc answerCount
      if heapSize > 0: shiftDown(0)
    elif operation == 3:
      if position + 1 >= int(length): return -1
      let key = input[position + 1]
      if key < -1_000_000_000'i64 or key > 1_000_000_000'i64: return -1
      position += 2
      answers[answerCount] = (if findKey(key) != heapSize: 1'i64 else: 0'i64); inc answerCount
    elif operation == 4:
      inc position
      answers[answerCount] = (if heapSize == 0: 1'i64 else: 0'i64); inc answerCount
    else: return -1
  if position != int(length): return -1
  let outputLength = answerCount * 8
  if output == nil or int(outputCapacity) < outputLength: return -2
  for i in 0 ..< answerCount:
    let bits = cast[uint64](answers[i])
    for b in 0 ..< 8: output[i * 8 + b] = uint8((bits shr (8 * b)) and 255)
  int64(outputLength)
