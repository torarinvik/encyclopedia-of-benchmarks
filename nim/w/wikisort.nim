const cacheCapacity = csize_t(512)
const runSize = csize_t(16)
const maximumLength = csize_t(2048)

proc reverseRange(values: ptr UncheckedArray[int64], firstValue, lastValue: csize_t) =
  var first = firstValue
  var last = lastValue
  while first < last:
    dec last
    if first >= last:
      break
    swap(values[first], values[last])
    inc first

proc insertionSort(values: ptr UncheckedArray[int64], first, last: csize_t) =
  var index = first + 1
  while index < last:
    let item = values[index]
    var position = index
    while position > first and item < values[position - 1]:
      values[position] = values[position - 1]
      dec position
    values[position] = item
    inc index

proc rotateAdjacent(values, scratch: ptr UncheckedArray[int64], first, middle, last, cacheSize: csize_t) =
  let leftLength = middle - first
  let rightLength = last - middle
  if leftLength == 0 or rightLength == 0:
    return
  if leftLength <= rightLength and leftLength <= cacheSize:
    for index in 0 ..< leftLength:
      scratch[index] = values[first + index]
    for index in 0 ..< rightLength:
      values[first + index] = values[middle + index]
    for index in 0 ..< leftLength:
      values[first + rightLength + index] = scratch[index]
    return
  if rightLength < leftLength and rightLength <= cacheSize:
    for index in 0 ..< rightLength:
      scratch[index] = values[middle + index]
    var index = leftLength
    while index > 0:
      dec index
      values[first + rightLength + index] = values[first + index]
    for index in 0 ..< rightLength:
      values[first + index] = scratch[index]
    return
  reverseRange(values, first, middle)
  reverseRange(values, middle, last)
  reverseRange(values, first, last)

proc mergeFromCache(values, scratch: ptr UncheckedArray[int64], first, middle, last: csize_t) =
  let leftLength = middle - first
  for index in 0 ..< leftLength:
    scratch[index] = values[first + index]
  var left = csize_t(0)
  var right = middle
  var output = first
  while left < leftLength and right < last:
    if scratch[left] <= values[right]:
      values[output] = scratch[left]
      inc left
    else:
      values[output] = values[right]
      inc right
    inc output
  while left < leftLength:
    values[output] = scratch[left]
    inc left
    inc output

proc blockRotationMerge(values, scratch: ptr UncheckedArray[int64], first, middleValue, last, cacheSize: csize_t) =
  let total = last - first
  var blockSize = csize_t(1)
  while blockSize + 1 <= total div (blockSize + 1):
    inc blockSize
  var middle = middleValue
  var left = first
  while left < middle and middle < last:
    if values[left] <= values[middle]:
      let boundaryValue = values[middle]
      var low = left
      var high = middle
      while low < high:
        let probe = low + (high - low) div 2
        if values[probe] <= boundaryValue:
          low = probe + 1
        else:
          high = probe
      left = low
    else:
      let key = values[left]
      var low = middle
      var high = last
      while low < high:
        let probe = low + (high - low) div 2
        if values[probe] < key:
          low = probe + 1
        else:
          high = probe
      var blockEnd = low
      if blockEnd - middle > blockSize:
        blockEnd = middle + blockSize
      let moved = blockEnd - middle
      if moved == 0:
        inc left
      else:
        rotateAdjacent(values, scratch, left, middle, blockEnd, cacheSize)
        left += moved
        middle += moved

proc wikisort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "wikisort".} =
  if length < 2 or length > maximumLength:
    return
  let cacheSize = min(length, cacheCapacity)
  if length <= 32:
    insertionSort(values, 0, length)
    return
  var start = csize_t(0)
  while start < length:
    insertionSort(values, start, min(start + runSize, length))
    start += runSize
  var width = runSize
  while width < length:
    var first = csize_t(0)
    while first < length:
      let middle = min(first + width, length)
      let last = min(middle + width, length)
      if middle < last and values[middle] < values[middle - 1]:
        if values[last - 1] < values[first]:
          rotateAdjacent(values, scratch, first, middle, last, cacheSize)
        elif middle - first <= cacheSize:
          mergeFromCache(values, scratch, first, middle, last)
        else:
          blockRotationMerge(values, scratch, first, middle, last, cacheSize)
      first = last
    if width > length div 2:
      break
    width *= 2
