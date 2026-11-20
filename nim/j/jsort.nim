proc siftDownMin(values: ptr UncheckedArray[int64], rootValue, endValue: csize_t) =
  var root = rootValue
  while root < endValue div 2:
    var child = root * 2 + 1
    if child + 1 < endValue and values[child + 1] < values[child]:
      inc child
    if values[root] <= values[child]:
      break
    swap(values[root], values[child])
    root = child

proc siftDownMax(values: ptr UncheckedArray[int64], rootValue, endValue: csize_t) =
  var root = rootValue
  while root < endValue div 2:
    var child = root * 2 + 1
    if child + 1 < endValue and values[child + 1] > values[child]:
      inc child
    if values[root] >= values[child]:
      break
    swap(values[root], values[child])
    root = child

proc reverseValues(values: ptr UncheckedArray[int64], length: csize_t) =
  for left in 0 ..< length div 2:
    let right = length - 1 - left
    swap(values[left], values[right])

proc jsort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "jsort".} =
  if values == nil or length < 2:
    return
  var start = length div 2
  while start > 0:
    dec start
    siftDownMin(values, start, length)

  reverseValues(values, length)
  start = length div 2
  while start > 0:
    dec start
    siftDownMax(values, start, length)
  reverseValues(values, length)

  var index: csize_t = 1
  while index < length:
    let key = values[index]
    var position = index
    while position > 0 and values[position - 1] > key:
      values[position] = values[position - 1]
      dec position
    values[position] = key
    inc index
