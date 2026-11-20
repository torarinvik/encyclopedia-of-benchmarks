proc innerAdd(trees: var array[150, int64], n, node: int, y, delta: int64) =
  var index = int(y) + 1
  while index <= n:
    trees[node * 25 + index] += delta
    index += index and -index

proc innerPrefix(trees: array[150, int64], node: int, yLimit: int64): int64 =
  var index = int(yLimit)
  while index > 0:
    result += trees[node * 25 + index]
    index = index and (index - 1)

proc prefixCount(ys: array[24, int64], trees: array[150, int64], blockSize,
                 xLimit: int, yLimit: int64): int64 =
  let fullBlocks = xLimit div blockSize
  var node = fullBlocks
  while node > 0:
    result += innerPrefix(trees, node, yLimit)
    node = node and (node - 1)
  for x in (fullBlocks * blockSize) ..< xLimit:
    if ys[x] < yLimit: inc result

proc fenwick_tree_in_block_array_rectangle_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fenwick_tree_in_block_array_rectangle_count".} =
  if input.isNil or length < 2 or length > 187: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > 24 or qValue < 1 or qValue > 32: return -1
  let n = int(nValue)
  let q = int(qValue)
  let operationsAt = 2 + n
  if length != csize_t(operationsAt + 5 * q): return -1

  var ys: array[24, int64]
  for x in 0 ..< n:
    ys[x] = input[2 + x]
    if ys[x] < 0 or ys[x] >= nValue: return -1
  for j in 0 ..< q:
    let at = operationsAt + 5 * j
    let kind = input[at]
    if kind == 0:
      if input[at + 1] < 0 or input[at + 1] >= nValue
          or input[at + 2] < 0 or input[at + 2] >= nValue
          or input[at + 3] != 0 or input[at + 4] != 0: return -1
    elif kind == 1:
      if input[at + 1] < 0 or input[at + 1] > input[at + 2]
          or input[at + 2] > nValue
          or input[at + 3] < 0 or input[at + 3] > input[at + 4]
          or input[at + 4] > nValue: return -1
    else:
      return -1

  var blockSize = 1
  while blockSize * blockSize < n: inc blockSize
  let blockCount = (n + blockSize - 1) div blockSize
  var trees: array[150, int64]
  for x in 0 ..< n:
    var node = x div blockSize + 1
    while node <= blockCount:
      innerAdd(trees, n, node, ys[x], 1)
      node += node and -node

  var checksum = 0'i64
  var queryOrdinal = 0'i64
  for j in 0 ..< q:
    let at = operationsAt + 5 * j
    if input[at] == 0:
      let x = int(input[at + 1])
      let newY = input[at + 2]
      var node = x div blockSize + 1
      while node <= blockCount:
        innerAdd(trees, n, node, ys[x], -1)
        innerAdd(trees, n, node, newY, 1)
        node += node and -node
      ys[x] = newY
    else:
      let xLeft = int(input[at + 1])
      let xRight = int(input[at + 2])
      let yLow = input[at + 3]
      let yHigh = input[at + 4]
      let count = prefixCount(ys, trees, blockSize, xRight, yHigh)
        - prefixCount(ys, trees, blockSize, xLeft, yHigh)
        - prefixCount(ys, trees, blockSize, xRight, yLow)
        + prefixCount(ys, trees, blockSize, xLeft, yLow)
      inc queryOrdinal
      checksum += queryOrdinal * count
  checksum
