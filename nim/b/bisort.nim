const
  MinSize = 2
  MaxSize = 1024
  MaxNodes = MaxSize - 1
  Modulus = 10000'i32
  Multiplier = 31415821'i32
  ValueRange = 100'i32

type Node = object
  value: int32
  left: int32
  right: int32

proc multiply(p, q: int32): int32 =
  let pHigh = p div Modulus
  let pLow = p mod Modulus
  let qHigh = q div Modulus
  let qLow = q mod Modulus
  ((pLow * qHigh + pHigh * qLow) mod Modulus) * Modulus + pLow * qLow

proc nextRandom(seed: int32): int32 = multiply(seed, Multiplier) + 1

proc skipRandom(seedValue: int32, count: int32): int32 =
  var seed = seedValue
  for _ in 0'i32 ..< count:
    seed = nextRandom(seed)
  seed

proc makeTree(nodes: var array[MaxNodes, Node], used: var int,
              size, seedValue: int32): int32 =
  if size <= 1: return -1
  let seed = nextRandom(seedValue)
  let index = int32(used)
  inc used
  nodes[int(index)].value = seed mod ValueRange
  let half = size div 2
  nodes[int(index)].left = makeTree(nodes, used, half, seed)
  nodes[int(index)].right = makeTree(nodes, used, half, skipRandom(seed, size + 1))
  index

proc swapLeft(nodes: var array[MaxNodes, Node], left, right, leftLeft, rightLeft,
              leftValue, rightValue: int32) =
  nodes[int(right)].value = leftValue
  nodes[int(right)].left = leftLeft
  nodes[int(left)].left = rightLeft
  nodes[int(left)].value = rightValue

proc swapRight(nodes: var array[MaxNodes, Node], left, right, leftRight, rightRight,
               leftValue, rightValue: int32) =
  nodes[int(right)].value = leftValue
  nodes[int(right)].right = leftRight
  nodes[int(left)].right = rightRight
  nodes[int(left)].value = rightValue

proc merge(nodes: var array[MaxNodes, Node], root, spill, direction: int32): int32 =
  var savedSpill = spill
  var rootValue = nodes[int(root)].value
  var left = nodes[int(root)].left
  var right = nodes[int(root)].right
  let rightExchange = (rootValue > savedSpill) xor (direction != 0)
  if rightExchange:
    nodes[int(root)].value = savedSpill
    savedSpill = rootValue
  while left >= 0:
    let leftValue = nodes[int(left)].value
    let leftLeft = nodes[int(left)].left
    let leftRight = nodes[int(left)].right
    let rightValue = nodes[int(right)].value
    let rightLeft = nodes[int(right)].left
    let rightRight = nodes[int(right)].right
    let elementExchange = (leftValue > rightValue) xor (direction != 0)
    if rightExchange:
      if elementExchange:
        swapRight(nodes, left, right, leftRight, rightRight, leftValue, rightValue)
        left = leftLeft
        right = rightLeft
      else:
        left = leftRight
        right = rightRight
    elif elementExchange:
      swapLeft(nodes, left, right, leftLeft, rightLeft, leftValue, rightValue)
      left = leftRight
      right = rightRight
    else:
      left = leftLeft
      right = rightLeft
  if nodes[int(root)].left >= 0:
    let leftRoot = nodes[int(root)].left
    let rightRoot = nodes[int(root)].right
    rootValue = nodes[int(root)].value
    nodes[int(root)].value = merge(nodes, leftRoot, rootValue, direction)
    savedSpill = merge(nodes, rightRoot, savedSpill, direction)
  savedSpill

proc sortTree(nodes: var array[MaxNodes, Node], root, spill, direction: int32): int32 =
  var nextSpill = spill
  if nodes[int(root)].left < 0:
    if (nodes[int(root)].value > nextSpill) xor (direction != 0):
      let value = nodes[int(root)].value
      nodes[int(root)].value = nextSpill
      nextSpill = value
    return nextSpill
  let left = nodes[int(root)].left
  let right = nodes[int(root)].right
  let value = nodes[int(root)].value
  nodes[int(root)].value = sortTree(nodes, left, value, direction)
  nextSpill = sortTree(nodes, right, nextSpill, if direction == 0: 1 else: 0)
  merge(nodes, root, nextSpill, direction)

proc checksum(nodes: openArray[Node], index: int32,
               position: var int64, sum: var int64) =
  if index < 0: return
  checksum(nodes, nodes[int(index)].left, position, sum)
  inc position
  sum += position * int64(nodes[int(index)].value)
  checksum(nodes, nodes[int(index)].right, position, sum)

proc bisort*(size: int64): int64 {.cdecl, exportc: "bisort".} =
  if size < int64(MinSize) or size > int64(MaxSize): return -1
  var nodes: array[MaxNodes, Node]
  var used = 0
  let root = makeTree(nodes, used, int32(size), 12345768'i32)
  var spill = nextRandom(245867'i32) mod ValueRange
  spill = sortTree(nodes, root, spill, 0)
  spill = sortTree(nodes, root, spill, 1)
  var position = 0'i64
  var sum = 0'i64
  checksum(nodes, root, position, sum)
  inc position
  sum + position * int64(spill)
