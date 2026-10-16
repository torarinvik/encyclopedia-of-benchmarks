const MaxPoints = 64

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  IndexArray = array[MaxPoints, int]

proc cross(a, b, c: int, values: I64Input): int64 =
  let ax = values[2*a]; let ay = values[2*a+1]
  let bx = values[2*b]; let by = values[2*b+1]
  let cx = values[2*c]; let cy = values[2*c+1]
  (bx-ax)*(cy-ay) - (by-ay)*(cx-ax)

proc orientation(a, b, c: int, values: I64Input): int =
  let turn = cross(a, b, c, values)
  if turn < 0: return 1
  if turn > 0: return -1
  0

proc sortIndices(items, scratch: var IndexArray, beginIndex, endIndex: int, values: I64Input) =
  if endIndex - beginIndex < 2: return
  let middle = beginIndex + (endIndex - beginIndex) div 2
  sortIndices(items, scratch, beginIndex, middle, values)
  sortIndices(items, scratch, middle, endIndex, values)
  var left = beginIndex
  var right = middle
  var outputIndex = beginIndex
  while left < middle and right < endIndex:
    if values[2*items[right]] < values[2*items[left]]:
      scratch[outputIndex] = items[right]
      inc right
    else:
      scratch[outputIndex] = items[left]
      inc left
    inc outputIndex
  while left < middle:
    scratch[outputIndex] = items[left]
    inc left
    inc outputIndex
  while right < endIndex:
    scratch[outputIndex] = items[right]
    inc right
    inc outputIndex
  for index in beginIndex ..< endIndex: items[index] = scratch[index]

proc putIndex(output: U8Output, position, id: int) =
  let value = uint32(id)
  for byte in 0 ..< 4:
    output[4*position+byte] = uint8((value shr (8*byte)) and 255'u32)

proc convex_hull_graham*(input: I64Input, length: csize_t,
    output: U8Output, capacity: csize_t): int64 {.cdecl, exportc: "convex_hull_graham".} =
  if input == nil or length mod 2 != 0 or length > csize_t(2*MaxPoints): return -1
  let count = int(length div 2)
  if count < 3 or count > MaxPoints: return -1
  for index in 0 ..< 2*count:
    if input[index] < -2000 or input[index] > 2000: return -1

  var order, scratch, upper, lower: IndexArray
  for index in 0 ..< count: order[index] = index
  sortIndices(order, scratch, 0, count, input)
  for index in 1 ..< count:
    if input[2*order[index-1]] == input[2*order[index]]: return -1
  for index in 1 ..< (count - 1):
    if cross(order[0], order[index], order[count-1], input) == 0: return -1

  var upperCount = 1
  var lowerCount = 1
  upper[0] = 0
  lower[0] = 0
  for index in 1 ..< count:
    let turn = orientation(order[0], order[index], order[count-1], input)
    if index == count-1 or turn != -1:
      while upperCount >= 2 and orientation(order[upper[upperCount-2]],
          order[upper[upperCount-1]], order[index], input) == -1: dec upperCount
      upper[upperCount] = index
      inc upperCount
    if index == count-1 or turn != 1:
      while lowerCount >= 2 and orientation(order[lower[lowerCount-2]],
          order[lower[lowerCount-1]], order[index], input) == 1: dec lowerCount
      lower[lowerCount] = index
      inc lowerCount

  let hullCount = upperCount - 2 + lowerCount
  if output == nil or capacity < csize_t(4*hullCount): return -2
  var written = 0
  for index in 1 ..< (upperCount - 1):
    putIndex(output, written, order[upper[index]])
    inc written
  for index in countdown(lowerCount-1, 0):
    putIndex(output, written, order[lower[index]])
    inc written
  int64(hullCount)
