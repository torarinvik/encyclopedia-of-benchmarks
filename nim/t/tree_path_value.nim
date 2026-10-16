## Port of Go Problem18's chunked search over its triangle-shaped DAG.
proc tree_path_value*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_path_value".} =
  if length < 1 or length > 121 or packed.isNil: return -1
  if packed[0] < 1 or packed[0] > 14: return -1
  let depth = int(packed[0])
  let count = int(length) - 1
  if count == 0: return 0

  var values: array[120, int64]
  var leftChildren: array[120, int]
  var rightChildren: array[120, int]
  for index in 0 ..< count:
    values[index] = packed[index + 1]
    leftChildren[index] = -1
    rightChildren[index] = -1
    if index == 0 and (values[index] < -1000 or values[index] > 1000): return -1
    if index > 0 and (values[index] < 1 or values[index] > 1000): return -1

  var rowStart = 0
  var width = 1
  while rowStart < count:
    for column in 0 ..< width:
      if rowStart + column >= count: break
      let parent = rowStart + column
      let leftIndex = rowStart + width + column
      let rightIndex = leftIndex + 1
      if leftIndex < count: leftChildren[parent] = leftIndex
      if rightIndex < count: rightChildren[parent] = rightIndex
    rowStart += width
    inc width

  var pivot = 0
  var maximum = values[0]
  while leftChildren[pivot] >= 0:
    var stackNode: array[16, int]
    var stackSteps: array[16, int]
    var stackSum: array[16, int64]
    var stackSize = 1
    stackNode[0] = pivot
    stackSteps[0] = depth
    stackSum[0] = maximum
    while stackSize > 0:
      dec stackSize
      let node = stackNode[stackSize]
      let steps = stackSteps[stackSize]
      let sum = stackSum[stackSize]
      if steps == 0:
        if sum > maximum:
          maximum = sum
          pivot = node
        continue
      if rightChildren[node] >= 0:
        let child = rightChildren[node]
        stackNode[stackSize] = child
        stackSteps[stackSize] = steps - 1
        stackSum[stackSize] = sum + values[child]
        inc stackSize
      if leftChildren[node] >= 0:
        let child = leftChildren[node]
        stackNode[stackSize] = child
        stackSteps[stackSize] = steps - 1
        stackSum[stackSize] = sum + values[child]
        inc stackSize
      elif sum > maximum:
        maximum = sum
        pivot = node
  maximum
