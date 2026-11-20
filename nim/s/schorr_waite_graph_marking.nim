proc schorr_waite_graph_marking*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "schorr_waite_graph_marking".} =
  if input == nil or length < 4 or length > 66: return -1

  let nodeCountValue = input[0]
  let root = input[1]
  if nodeCountValue < 1 or nodeCountValue > 32: return -1
  let nodeCount = int(nodeCountValue)
  if length != csize_t(2 + 2 * nodeCount) or root < 0 or root >= nodeCountValue:
    return -1

  var left: array[32, int64]
  var right: array[32, int64]
  var marked: array[32, bool]
  var phase: array[32, bool]
  for node in 0..<nodeCount:
    let leftChild = input[2 + 2 * node]
    let rightChild = input[3 + 2 * node]
    if leftChild < -1 or leftChild >= nodeCountValue
        or rightChild < -1 or rightChild >= nodeCountValue:
      return -1
    left[node] = leftChild
    right[node] = rightChild

  var parent = -1'i64
  var current = root
  var temporary: int64
  while parent != -1 or (current != -1 and not marked[int(current)]):
    if current == -1 or marked[int(current)]:
      let frame = int(parent)
      if phase[frame]:
        temporary = current
        current = parent
        parent = right[frame]
        right[frame] = temporary
      else:
        temporary = current
        current = right[frame]
        right[frame] = left[frame]
        left[frame] = temporary
        phase[frame] = true
    else:
      temporary = parent
      parent = current
      current = left[int(parent)]
      left[int(parent)] = temporary
      marked[int(parent)] = true
      phase[int(parent)] = false

  var reachable = 0'i64
  for node in 0..<nodeCount:
    if marked[node]: reachable = reachable or (1'i64 shl node)
  return reachable
