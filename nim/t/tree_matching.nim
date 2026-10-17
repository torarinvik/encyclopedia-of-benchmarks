const MaxNodes = 64
const MaxInputValues = 2 + 3 * (MaxNodes - 1)
const MatrixSize = MaxNodes * MaxNodes

type
  AdjMatrix = array[MatrixSize, bool]
  WeightMatrix = array[MatrixSize, int64]

proc matchingDp(node, parent, count: int, adjacent: var AdjMatrix, weights: var WeightMatrix,
    visited: var array[MaxNodes, bool], parentOf: var array[MaxNodes, int],
    withoutEdge, withEdge: var array[MaxNodes, int64], reached: var int) =
  visited[node] = true
  parentOf[node] = parent
  inc reached
  var base = 0'i64
  for child in 0 ..< count:
    let index = node * MaxNodes + child
    if adjacent[index] and child != parent and not visited[child]:
      matchingDp(child, node, count, adjacent, weights, visited, parentOf, withoutEdge, withEdge, reached)
      base += max(withoutEdge[child], withEdge[child])
  withoutEdge[node] = base
  withEdge[node] = 0
  for child in 0 ..< count:
    if parentOf[child] == node:
      let childBest = max(withoutEdge[child], withEdge[child])
      let candidate = base - childBest + withoutEdge[child] + weights[node * MaxNodes + child]
      withEdge[node] = max(withEdge[node], candidate)

proc tree_matching*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "tree_matching".} =
  if values.isNil or length < 2 or length > MaxInputValues: return -1
  if values[0] < 1 or values[0] > MaxNodes: return -1
  let count = int(values[0])
  if int(length) != 2 + 3 * (count - 1) or values[1] < 0 or values[1] >= count: return -1
  var adjacent: AdjMatrix
  var weights: WeightMatrix
  for edge in 0 ..< count - 1:
    let aValue = values[2 + 3 * edge]
    let bValue = values[3 + 3 * edge]
    let weight = values[4 + 3 * edge]
    if aValue < 0 or bValue < 0 or aValue >= count or bValue >= count or aValue == bValue or weight < 0 or weight > 1000: return -1
    let a = int(aValue); let b = int(bValue)
    let ab = a * MaxNodes + b
    let ba = b * MaxNodes + a
    if adjacent[ab]: return -1
    adjacent[ab] = true; adjacent[ba] = true
    weights[ab] = weight; weights[ba] = weight
  var visited: array[MaxNodes, bool]
  var parentOf: array[MaxNodes, int]
  for node in 0 ..< MaxNodes: parentOf[node] = -2
  var withoutEdge: array[MaxNodes, int64]
  var withEdge: array[MaxNodes, int64]
  var reached = 0
  let root = int(values[1])
  matchingDp(root, -1, count, adjacent, weights, visited, parentOf, withoutEdge, withEdge, reached)
  if reached != count: return -1
  max(withoutEdge[root], withEdge[root])
