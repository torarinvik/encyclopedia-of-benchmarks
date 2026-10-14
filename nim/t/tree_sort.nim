## Binary-search-tree sort with iterative insertion and in-order traversal.
const MaxValues = 1024

proc tree_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "tree_sort".} =
  if length > csize_t(MaxValues): return
  let n = int(length)
  var keys: array[MaxValues, int64]
  var left: array[MaxValues, int]
  var right: array[MaxValues, int]
  var stack: array[MaxValues, int]
  var root = n
  for index in 0 ..< n:
    keys[index] = values[index]
    left[index] = n
    right[index] = n
    if root == n:
      root = index
    else:
      var node = root
      while true:
        if keys[index] < keys[node]:
          if left[node] == n: left[node] = index; break
          node = left[node]
        else:
          if right[node] == n: right[node] = index; break
          node = right[node]
  var current = root
  var stackSize = 0
  var output = 0
  while current != n or stackSize > 0:
    while current != n:
      stack[stackSize] = current
      inc stackSize
      current = left[current]
    dec stackSize
    current = stack[stackSize]
    values[output] = keys[current]
    inc output
    current = right[current]
