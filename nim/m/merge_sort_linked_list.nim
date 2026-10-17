const MaxItems = 128

proc mergeNodes(values: openArray[int32], links: var array[MaxItems, int32], left, right: int32): int32 =
  if left < 0: return right
  if right < 0: return left
  let leftIndex = int(left)
  let rightIndex = int(right)
  if values[leftIndex] <= values[rightIndex]:
    let following = links[leftIndex]
    links[leftIndex] = mergeNodes(values, links, following, right)
    return left
  let following = links[rightIndex]
  links[rightIndex] = mergeNodes(values, links, left, following)
  right

proc mergeSortNodes(values: openArray[int32], links: var array[MaxItems, int32], head: int32): int32 =
  if head < 0 or links[int(head)] < 0: return head
  var slow = head
  var fast = links[int(head)]
  while fast >= 0 and links[int(fast)] >= 0:
    slow = links[int(slow)]
    fast = links[int(links[int(fast)])]
  let rightHead = links[int(slow)]
  links[int(slow)] = -1
  let left = mergeSortNodes(values, links, head)
  let right = mergeSortNodes(values, links, rightHead)
  mergeNodes(values, links, left, right)

proc merge_sort_linked_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "merge_sort_linked_list".} =
  if input == nil or length < 1 or length > 129: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxItems: return -1
  let count = int(countValue)
  if length != csize_t(1 + count): return -1
  var values: array[MaxItems, int32]
  var links: array[MaxItems, int32]
  for i in 0 ..< count:
    if input[1 + i] < int64(low(int32)) or input[1 + i] > int64(high(int32)): return -1
    values[i] = int32(input[1 + i])
    for j in 0 ..< i:
      if values[j] == values[i]: return -1
    links[i] = if i + 1 < count: int32(i + 1) else: -1
  let head = if count == 0: -1'i32 else: mergeSortNodes(values, links, 0)
  let required = 4 * count
  if output == nil or outputCapacity < csize_t(required): return -2
  var node = head
  for i in 0 ..< count:
    var bits = cast[uint32](values[int(node)])
    for byte in 0 ..< 4:
      output[i * 4 + byte] = uint8(bits and 255)
      bits = bits shr 8
    node = links[int(node)]
  int64(required)
