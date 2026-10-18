import std/math

const MaxRows = 8
const MaxFeatures = 4
const MaxNodes = 31
const MaxInput = 62

type TreeNode = object
  feature: int
  threshold: float64
  label: int
  left: int
  right: int
  leaf: bool

proc finiteValue(value: float64): bool = classify(value) notin {fcNan, fcInf, fcNegInf}

proc entropy(rows: array[MaxRows, int], start, count: int, labels: array[MaxRows, int]): float64 =
  if count == 0: return 0.0
  var classes: array[3, int]
  var counts: array[3, int]
  var classCount = 0
  for i in start ..< start + count:
    let label = labels[rows[i]]
    var found = -1
    for c in 0 ..< classCount:
      if classes[c] == label: found = c
    if found < 0:
      found = classCount
      classes[classCount] = label
      classCount += 1
    counts[found] += 1
  var result = 0.0
  for c in 0 ..< classCount:
    let probability = float64(counts[c]) / float64(count)
    result += probability * log2(probability)
  -result

proc buildTree(rows: array[MaxRows, int], rowCount, featureCount, maxDepth,
    minSamples, depth: int, data: array[MaxRows * MaxFeatures, float64],
    labels: array[MaxRows, int], nodes: var array[MaxNodes, TreeNode],
    nodeCount: var int): int =
  let nodeIndex = nodeCount
  nodeCount += 1
  var node: TreeNode
  node.feature = -1
  node.left = -1
  node.right = -1
  node.leaf = true
  var classes: array[3, int]
  var counts: array[3, int]
  var classCount = 0
  for i in 0 ..< rowCount:
    let label = labels[rows[i]]
    var found = -1
    for c in 0 ..< classCount:
      if classes[c] == label: found = c
    if found < 0:
      found = classCount
      classes[classCount] = label
      classCount += 1
    counts[found] += 1
  var bestClass = 0
  for c in 1 ..< classCount:
    if counts[c] > counts[bestClass]: bestClass = c
  node.label = classes[bestClass]
  nodes[nodeIndex] = node
  if classCount == 1 or rowCount < minSamples or depth >= maxDepth or featureCount == 0:
    return nodeIndex

  let parentEntropy = entropy(rows, 0, rowCount, labels)
  var bestGain = 0.0
  var bestFeature = -1
  var bestThreshold = 0.0
  for feature in 0 ..< featureCount:
    var sortedRows = rows
    for i in 1 ..< rowCount:
      let row = sortedRows[i]
      var j = i
      while j > 0 and data[sortedRows[j - 1] * MaxFeatures + feature] > data[row * MaxFeatures + feature]:
        sortedRows[j] = sortedRows[j - 1]
        j -= 1
      sortedRows[j] = row
    for index in 1 ..< rowCount:
      let leftValue = data[sortedRows[index - 1] * MaxFeatures + feature]
      let rightValue = data[sortedRows[index] * MaxFeatures + feature]
      if leftValue == rightValue: continue
      let gain = parentEntropy - float64(index) / float64(rowCount) * entropy(sortedRows, 0, index, labels) -
        float64(rowCount - index) / float64(rowCount) * entropy(sortedRows, index, rowCount - index, labels)
      if gain > bestGain:
        bestGain = gain
        bestFeature = feature
        bestThreshold = (leftValue + rightValue) / 2.0
  if bestFeature < 0: return nodeIndex
  var leftRows: array[MaxRows, int]
  var rightRows: array[MaxRows, int]
  var leftCount = 0
  var rightCount = 0
  for i in 0 ..< rowCount:
    let row = rows[i]
    if data[row * MaxFeatures + bestFeature] < bestThreshold:
      leftRows[leftCount] = row
      leftCount += 1
    else:
      rightRows[rightCount] = row
      rightCount += 1
  if leftCount == 0 or rightCount == 0: return nodeIndex
  nodes[nodeIndex].feature = bestFeature
  nodes[nodeIndex].threshold = bestThreshold
  nodes[nodeIndex].leaf = false
  nodes[nodeIndex].left = buildTree(leftRows, leftCount, featureCount, maxDepth, minSamples, depth + 1, data, labels, nodes, nodeCount)
  nodes[nodeIndex].right = buildTree(rightRows, rightCount, featureCount, maxDepth, minSamples, depth + 1, data, labels, nodes, nodeCount)
  nodeIndex

proc decision_tree_rust_id3*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "decision_tree_rust_id3".} =
  if input == nil or inputLength < 10 or inputLength > csize_t(MaxInput): return -1
  for i in 0 ..< int(inputLength):
    if not finiteValue(input[i]): return -1
  for i in 0 ..< 4:
    if input[i] != floor(input[i]): return -1
  if input[0] < 0 or input[0] > 6 or input[1] < 2 or input[1] > 8 or
      input[2] < 2 or input[2] > 8 or input[3] < 1 or input[3] > 4: return -1
  let maxDepth = int(input[0]); let minSamples = int(input[1]); let sampleCount = int(input[2]); let featureCount = int(input[3])
  let rowWidth = featureCount + 1
  let queryCountIndex = 4 + sampleCount * rowWidth
  if int(inputLength) <= queryCountIndex or input[queryCountIndex] != floor(input[queryCountIndex]) or
      input[queryCountIndex] < 1 or input[queryCountIndex] > 4: return -1
  let queryCount = int(input[queryCountIndex])
  let queryStart = queryCountIndex + 1
  if int(inputLength) != queryStart + queryCount * featureCount or inputLength > 61: return -1
  var data: array[MaxRows * MaxFeatures, float64]
  var labels: array[MaxRows, int]
  for row in 0 ..< sampleCount:
    for feature in 0 ..< featureCount:
      let value = input[4 + row * rowWidth + feature]
      if value < -4 or value > 4 or value * 4 != floor(value * 4): return -1
      data[row * MaxFeatures + feature] = value
    let label = input[4 + row * rowWidth + featureCount]
    if label != floor(label) or label < 0 or label > 2: return -1
    labels[row] = int(label)
  for i in 0 ..< queryCount * featureCount:
    let value = input[queryStart + i]
    if value < -4 or value > 4 or value * 4 != floor(value * 4): return -1
  var rows: array[MaxRows, int]
  for i in 0 ..< sampleCount: rows[i] = i
  var nodes: array[MaxNodes, TreeNode]
  var nodeCount = 0
  let root = buildTree(rows, sampleCount, featureCount, maxDepth, minSamples, 0, data, labels, nodes, nodeCount)
  var staged: array[5, float64]
  staged[0] = float64(queryCount)
  for q in 0 ..< queryCount:
    var nodeIndex = root
    while not nodes[nodeIndex].leaf:
      let feature = nodes[nodeIndex].feature
      if input[queryStart + q * featureCount + feature] < nodes[nodeIndex].threshold:
        nodeIndex = nodes[nodeIndex].left
      else:
        nodeIndex = nodes[nodeIndex].right
    staged[q + 1] = float64(nodes[nodeIndex].label)
  if output == nil or capacity < csize_t(queryCount + 1): return -2
  for i in 0 ..< queryCount + 1: output[i] = staged[i]
  int64(queryCount + 1)
