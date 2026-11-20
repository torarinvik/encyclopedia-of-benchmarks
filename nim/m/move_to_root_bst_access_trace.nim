const
  MaxInitial = 16
  MaxAccesses = 32

proc move_to_root_bst_access_trace*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "move_to_root_bst_access_trace".} =
  if values == nil or length < 2 or length > 51: return -1
  let initialCount = values[0]
  if initialCount < 0 or initialCount > MaxInitial: return -1
  let queryCountIndex = 1 + int(initialCount)
  if length < csize_t(queryCountIndex + 1): return -1
  let accessCount = values[queryCountIndex]
  if accessCount < 0 or accessCount > MaxAccesses: return -1
  if length != csize_t(queryCountIndex + 1 + int(accessCount)): return -1

  var keys: array[MaxInitial, int64]
  var left: array[MaxInitial, int32]
  var right: array[MaxInitial, int32]
  var parent: array[MaxInitial, int32]
  for index in 0 ..< MaxInitial:
    left[index] = -1
    right[index] = -1
    parent[index] = -1
  for index in 0 ..< int(initialCount):
    let key = values[1 + index]
    if key < -100 or key > 100: return -1
    for earlier in 0 ..< index:
      if values[1 + earlier] == key: return -1
    keys[index] = key
  for query in 0 ..< int(accessCount):
    let key = values[queryCountIndex + 1 + query]
    if key < -100 or key > 100: return -1

  var root: int32 = -1
  for nodeIndex in 0 ..< int(initialCount):
    let node = int32(nodeIndex)
    if root == -1:
      root = node
      continue
    var current = root
    while true:
      if keys[nodeIndex] < keys[int(current)]:
        if left[int(current)] == -1:
          left[int(current)] = node
          parent[nodeIndex] = current
          break
        current = left[int(current)]
      else:
        if right[int(current)] == -1:
          right[int(current)] = node
          parent[nodeIndex] = current
          break
        current = right[int(current)]

  var score: int64 = 0
  for queryNumber in 1 .. int(accessCount):
    let key = values[queryCountIndex + queryNumber]
    var node = root
    var comparisons: int64 = 0
    while node != -1:
      inc comparisons
      if key == keys[int(node)]: break
      if key < keys[int(node)]: node = left[int(node)]
      else: node = right[int(node)]
    while node != -1 and parent[int(node)] != -1:
      let oldParent = parent[int(node)]
      let grandparent = parent[int(oldParent)]
      if left[int(oldParent)] == node:
        let middle = right[int(node)]
        right[int(node)] = oldParent
        left[int(oldParent)] = middle
        if middle != -1: parent[int(middle)] = oldParent
      else:
        let middle = left[int(node)]
        left[int(node)] = oldParent
        right[int(oldParent)] = middle
        if middle != -1: parent[int(middle)] = oldParent
      parent[int(oldParent)] = node
      parent[int(node)] = grandparent
      if grandparent == -1: root = node
      elif left[int(grandparent)] == oldParent: left[int(grandparent)] = node
      else: right[int(grandparent)] = node
    score += int64(queryNumber) * comparisons
  score
