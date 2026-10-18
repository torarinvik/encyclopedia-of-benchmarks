import math

const MaxSamples = 12
const MaxQueries = 12
const MaxTreeNodes = 23

type TreeNode = object
  prediction: float64
  boundary: float64
  left: int
  right: int
  isLeaf: bool

proc finite(value: float64): bool = classify(value) notin {fcNan, fcInf, fcNegInf}

proc meanY(input: ptr UncheckedArray[float64], samples, start, count: int): float64 =
  var total = 0.0
  for i in 0 ..< count: total += input[3 + samples + start + i]
  total / float64(count)

proc featureMse(input: ptr UncheckedArray[float64], start, count: int, prediction: float64): float64 =
  var total = 0.0
  for i in 0 ..< count:
    let difference = input[3 + start + i] - prediction
    total += difference * difference
  total / float64(count)

proc buildTree(input: ptr UncheckedArray[float64], samples, start, count, depth, minLeaf: int,
    nodes: var array[MaxTreeNodes, TreeNode], nextNode: var int): int =
  let node = nextNode
  inc nextNode
  let totalMean = meanY(input, samples, start, count)
  if count < 2 * minLeaf or depth == 1:
    nodes[node].isLeaf = true
    nodes[node].prediction = totalMean
    return node
  var bestSplit = 0
  var minimumError = 2.0 * featureMse(input, start, count, totalMean)
  for split in minLeaf .. count - minLeaf:
    let leftMean = meanY(input, samples, start, split)
    let rightCount = count - split
    let rightMean = meanY(input, samples, start + split, rightCount)
    let error = featureMse(input, start, split, leftMean) +
      featureMse(input, start + split, rightCount, rightMean)
    if error < minimumError:
      bestSplit = split
      minimumError = error
  if bestSplit == 0:
    nodes[node].isLeaf = true
    nodes[node].prediction = totalMean
    return node
  nodes[node].isLeaf = false
  nodes[node].boundary = input[3 + start + bestSplit]
  nodes[node].left = buildTree(input, samples, start, bestSplit, depth - 1, minLeaf, nodes, nextNode)
  nodes[node].right = buildTree(input, samples, start + bestSplit, count - bestSplit, depth - 1, minLeaf, nodes, nextNode)
  node

proc predictTree(query: float64, root: int, nodes: array[MaxTreeNodes, TreeNode]): float64 =
  var node = root
  while not nodes[node].isLeaf:
    if query >= nodes[node].boundary: node = nodes[node].right else: node = nodes[node].left
  nodes[node].prediction

proc decision_tree_python_regression*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "decision_tree_python_regression".} =
  if input == nil or inputLength < 8 or inputLength > 41: return -1
  for i in 0 ..< 3:
    if not finite(input[i]) or input[i] != floor(input[i]): return -1
  if input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6 or input[2] < 2 or input[2] > 12: return -1
  let depth = int(input[0])
  let minLeaf = int(input[1])
  let samples = int(input[2])
  let queryCountIndex = 3 + 2 * samples
  if inputLength <= csize_t(queryCountIndex): return -1
  let queryCountValue = input[queryCountIndex]
  if not finite(queryCountValue) or queryCountValue < 1 or queryCountValue > 12 or queryCountValue != floor(queryCountValue): return -1
  let queries = int(queryCountValue)
  if inputLength != csize_t(queryCountIndex + 1 + queries) or inputLength > 40: return -1
  for i in 3 ..< queryCountIndex:
    if not finite(input[i]) or input[i] != floor(input[i]) or abs(input[i]) > 8: return -1
  for i in queryCountIndex + 1 ..< int(inputLength):
    if not finite(input[i]) or input[i] != floor(input[i]) or abs(input[i]) > 8: return -1
  var nodes: array[MaxTreeNodes, TreeNode]
  var nextNode = 0
  let root = buildTree(input, samples, 0, samples, depth, minLeaf, nodes, nextNode)
  var staged: array[MaxQueries + 1, float64]
  staged[0] = float64(queries)
  for i in 0 ..< queries:
    staged[i + 1] = predictTree(input[queryCountIndex + 1 + i], root,
      nodes)
  if output == nil or outputCapacity < csize_t(queries + 1): return -2
  for i in 0 ..< queries + 1: output[i] = staged[i]
  int64(queries + 1)
