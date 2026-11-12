const MaxN = 32
const MaxQ = 32
const MaxOutputBytes = 8 * MaxQ

proc treeSet(tree: var array[128, int32], base, value: int, present: int32) =
  var node = base + value
  tree[node] = present
  node = node div 2
  while node > 0:
    tree[node] = tree[2 * node] + tree[2 * node + 1]
    node = node div 2

proc findMex(tree: array[128, int32], base, domainSize: int): int =
  var node = 1
  var start = 0
  var span = base
  while span > 1:
    let half = span div 2
    let leftWidth = if start >= domainSize: 0 else: min(half, domainSize - start)
    if int(tree[2 * node]) < leftWidth:
      node *= 2
      span = half
    else:
      node = 2 * node + 1
      start += half
      span = half
  start

proc writeI64(staged: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    staged[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc dynamic_mex_updates*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dynamic_mex_updates".} =
  if input.isNil or length < 2 or length > 99: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 2 + n + 2 * q: return -1

  var current: array[MaxN, int64]
  var updateIndices: array[MaxQ, int]
  var updateValues: array[MaxQ, int64]
  for index in 0 ..< n:
    let value = input[2 + index]
    if value < -1000 or value > 1000: return -1
    current[index] = value
  var cursor = 2 + n
  for operation in 0 ..< q:
    let index = input[cursor]
    let value = input[cursor + 1]
    cursor += 2
    if index < 0 or index >= nValue or value < -1000 or value > 1000: return -1
    updateIndices[operation] = int(index)
    updateValues[operation] = value

  let needed = 8 * q
  if needed > 0 and (output.isNil or int(capacity) < needed): return -2
  var base = 1
  while base < n + 1: base *= 2
  var frequencies: array[MaxN + 1, int32]
  var tree: array[128, int32]
  for index in 0 ..< n:
    let value = current[index]
    if value >= 0 and value <= nValue: inc frequencies[int(value)]
  for value in 0 ..< n + 1:
    if frequencies[value] > 0: tree[base + value] = 1
  var node = base
  while node > 1:
    dec node
    tree[node] = tree[2 * node] + tree[2 * node + 1]

  var staged: array[MaxOutputBytes, uint8]
  for operation in 0 ..< q:
    let index = updateIndices[operation]
    let oldValue = current[index]
    let newValue = updateValues[operation]
    if oldValue != newValue:
      if oldValue >= 0 and oldValue <= nValue:
        let oldIndex = int(oldValue)
        dec frequencies[oldIndex]
        if frequencies[oldIndex] == 0: treeSet(tree, base, oldIndex, 0)
      if newValue >= 0 and newValue <= nValue:
        let newIndex = int(newValue)
        if frequencies[newIndex] == 0: treeSet(tree, base, newIndex, 1)
        inc frequencies[newIndex]
      current[index] = newValue
    writeI64(staged, 8 * operation, int64(findMex(tree, base, n + 1)))
  for byte in 0 ..< needed: output[byte] = staged[byte]
  int64(needed)
