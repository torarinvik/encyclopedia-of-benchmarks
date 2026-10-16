proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[word*8+byte] = uint8((bits shr (byte*8)) and 255'u64)

proc depth_first_search_iterative_order*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "depth_first_search_iterative_order".} =
  if input == nil or length < 3: return -1
  let nValue = input[0]
  let edgeValue = input[1]
  if nValue < 1 or nValue > 10 or edgeValue < 0 or edgeValue > 64: return -1
  let n = int(nValue)
  let edgeCount = int(edgeValue)
  if length != csize_t(3+2*edgeCount): return -1
  var adjacency: array[11, array[128, int]]
  var degree: array[11, int]
  var position = 2
  for _ in 0..<edgeCount:
    let leftValue = input[position]
    let rightValue = input[position+1]
    position += 2
    if leftValue < 1 or leftValue > nValue or rightValue < 1 or rightValue > nValue: return -1
    let left = int(leftValue)
    let right = int(rightValue)
    adjacency[left][degree[left]] = right
    inc degree[left]
    adjacency[right][degree[right]] = left
    inc degree[right]
  let startValue = input[position]
  if startValue < 1 or startValue > nValue: return -1
  let start = int(startValue)
  var stack: array[10, int]
  var order: array[10, int]
  var visited: array[11, bool]
  var stackSize = 1
  var orderCount = 0
  visited[start] = true
  stack[0] = start
  while stackSize > 0:
    dec stackSize
    let vertex = stack[stackSize]
    order[orderCount] = vertex
    inc orderCount
    for edge in 0..<degree[vertex]:
      let neighbor = adjacency[vertex][edge]
      if not visited[neighbor]:
        visited[neighbor] = true
        stack[stackSize] = neighbor
        inc stackSize
  let words = orderCount+1
  if output == nil or capacity < csize_t(words*8): return -2
  putI64Le(output, 0, int64(orderCount))
  for index in 0..<orderCount: putI64Le(output, index+1, int64(order[index]))
  int64(words*8)
