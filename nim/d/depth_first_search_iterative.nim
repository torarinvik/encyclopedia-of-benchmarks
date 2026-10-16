const MaxVertices = 64
const MaxEdges = 256
const MaxInputLength = 518
proc depth_first_search_iterative*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "depth_first_search_iterative".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  let sourceValue = input[2]
  let targetValue = input[3]
  if nValue < 1 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges: return -1
  if sourceValue < 0 or sourceValue >= nValue: return -1
  let m = int(mValue)
  if length != csize_t(4 + 2 * m): return -1
  for edge in 0 ..< m:
    let left = input[4 + 2 * edge]
    let right = input[5 + 2 * edge]
    if left < 0 or left >= nValue or right < 0 or right >= nValue: return -1
  var visited: array[MaxVertices, bool]
  var pending: array[MaxVertices, int]
  var top = 1
  pending[0] = int(sourceValue)
  visited[pending[0]] = true
  while top > 0:
    dec top
    let current = pending[top]
    if int64(current) == targetValue: return 1
    for edge in 0 ..< m:
      let left = input[4 + 2 * edge]
      let right = input[5 + 2 * edge]
      var neighbor = -1'i64
      if left == int64(current): neighbor = right
      elif right == int64(current): neighbor = left
      if neighbor >= 0:
        let index = int(neighbor)
        if not visited[index]:
          visited[index] = true
          pending[top] = index
          inc top
  return 0
