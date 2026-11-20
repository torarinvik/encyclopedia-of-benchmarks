const
  MaxText = 12
  MaxPattern = 8
  MaxSigma = 4
  MaxSuffixes = MaxText + 1
  MaxNodes = 2 * MaxSuffixes - 1
  MaxInput = 24
  MaxOutput = 16

type
  TrayNode = object
    edgeStart, edgeLength, depth, leafStart: int
    child: array[5, int]
    leafCount, saLeft, saRight: int
    sigma: bool
    kind, sigmaChildCount: int
    sigmaChild: array[5, int]
    childBySymbol, groupBySymbol: array[MaxSigma, int]
    gapCount: int
    gapLeft, gapRight: array[5, int]
    separator, onlySigmaChild: int
    leftValid, rightValid: bool
    leftInterval, rightInterval: array[2, int]

proc initNode(node: var TrayNode; start, edgeLength, depth, leaf: int) =
  node.edgeStart = start
  node.edgeLength = edgeLength
  node.depth = depth
  node.leafStart = leaf
  node.child.fill(-1)
  node.sigmaChild.fill(-1)
  node.childBySymbol.fill(-1)
  node.groupBySymbol.fill(-1)
  node.gapLeft.fill(-1)
  node.gapRight.fill(-1)
  node.leafCount = 0
  node.saLeft = 0
  node.saRight = -1
  node.sigma = false
  node.kind = 0
  node.sigmaChildCount = 0
  node.gapCount = 0
  node.separator = -1
  node.onlySigmaChild = -1
  node.leftValid = false
  node.rightValid = false
  node.leftInterval = [-1, -1]
  node.rightInterval = [-1, -1]

proc suffixCompare(text: array[MaxSuffixes, int]; a, b, textLength: int): int =
  var offset = 0
  while a + offset < textLength and b + offset < textLength:
    if text[a + offset] != text[b + offset]:
      return (if text[a + offset] < text[b + offset]: -1 else: 1)
    inc offset
  if a + offset == textLength and b + offset == textLength: return 0
  if a + offset == textLength: return -1
  1

proc buildSuffixArray(text: array[MaxSuffixes, int]; textLength: int;
                      suffixes, rank: var array[MaxSuffixes, int]) =
  for i in 0 ..< textLength: suffixes[i] = i
  for i in 1 ..< textLength:
    let item = suffixes[i]
    var j = i
    while j > 0 and suffixCompare(text, item, suffixes[j - 1], textLength) < 0:
      suffixes[j] = suffixes[j - 1]
      dec j
    suffixes[j] = item
  for i in 0 ..< textLength: rank[suffixes[i]] = i

proc insertSuffix(nodes: var array[MaxNodes, TrayNode]; nodeCount: var int;
                  text: array[MaxSuffixes, int]; textLength, start: int) =
  var current = 0
  var position = start
  while position < textLength:
    let symbol = text[position]
    let childId = nodes[current].child[symbol + 1]
    if childId < 0:
      let id = nodeCount
      inc nodeCount
      let edgeLength = textLength - position
      initNode(nodes[id], position, edgeLength, nodes[current].depth + edgeLength, start)
      nodes[current].child[symbol + 1] = id
      return
    var common = 0
    while common < nodes[childId].edgeLength and position + common < textLength and
        text[position + common] == text[nodes[childId].edgeStart + common]:
      inc common
    if common == nodes[childId].edgeLength:
      position += common
      current = childId
      continue
    let splitId = nodeCount
    inc nodeCount
    let oldStart = nodes[childId].edgeStart
    initNode(nodes[splitId], oldStart, common, nodes[current].depth + common, -1)
    nodes[current].child[symbol + 1] = splitId
    nodes[childId].edgeStart += common
    nodes[childId].edgeLength -= common
    nodes[splitId].child[text[nodes[childId].edgeStart] + 1] = childId
    let newStart = position + common
    let newId = nodeCount
    inc nodeCount
    let newLength = textLength - newStart
    initNode(nodes[newId], newStart, newLength, nodes[splitId].depth + newLength, start)
    nodes[splitId].child[text[newStart] + 1] = newId
    return

proc summarizeNode(nodes: var array[MaxNodes, TrayNode]; nodeId: int;
                   rank: array[MaxSuffixes, int]; sigma: int) =
  if nodes[nodeId].leafStart >= 0:
    nodes[nodeId].leafCount = 1
    nodes[nodeId].saLeft = rank[nodes[nodeId].leafStart]
    nodes[nodeId].saRight = nodes[nodeId].saLeft
    return
  var children: array[5, int]
  var count = 0
  for symbol in -1 ..< sigma:
    let child = nodes[nodeId].child[symbol + 1]
    if child >= 0:
      children[count] = child
      inc count
  nodes[nodeId].leafCount = 0
  nodes[nodeId].saLeft = MaxSuffixes
  nodes[nodeId].saRight = -1
  for i in 0 ..< count:
    let child = children[i]
    summarizeNode(nodes, child, rank, sigma)
    nodes[nodeId].leafCount += nodes[child].leafCount
    nodes[nodeId].saLeft = min(nodes[nodeId].saLeft, nodes[child].saLeft)
    nodes[nodeId].saRight = max(nodes[nodeId].saRight, nodes[child].saRight)

proc setInterval(valid: var bool; interval: var array[2, int];
                  nodes: openArray[TrayNode]; children: array[5, int]; count: int) =
  if count == 0:
    valid = false
    interval = [-1, -1]
    return
  valid = true
  interval[0] = nodes[children[0]].saLeft
  interval[1] = nodes[children[count - 1]].saRight

proc buildTray(nodes: var array[MaxNodes, TrayNode]; nodeCount, sigma: int;
               text: array[MaxSuffixes, int]) =
  for id in 0 ..< nodeCount: nodes[id].sigma = nodes[id].leafCount >= sigma
  for id in 0 ..< nodeCount:
    if not nodes[id].sigma: continue
    var children, sigmaChildren: array[5, int]
    var childCount = 0
    for symbol in -1 ..< sigma:
      let child = nodes[id].child[symbol + 1]
      if child >= 0:
        children[childCount] = child
        inc childCount
    var sigCount = 0
    for i in 0 ..< childCount:
      let child = children[i]
      if nodes[child].sigma:
        sigmaChildren[sigCount] = child
        inc sigCount
    nodes[id].sigmaChildCount = sigCount
    for i in 0 ..< sigCount: nodes[id].sigmaChild[i] = sigmaChildren[i]
    if sigCount == 0:
      nodes[id].kind = 3
      continue
    if sigCount == 1:
      nodes[id].kind = 2
      let child = sigmaChildren[0]
      nodes[id].onlySigmaChild = child
      nodes[id].separator = text[nodes[child].edgeStart]
      var left, right: array[5, int]
      var leftCount, rightCount = 0
      var after = false
      for i in 0 ..< childCount:
        let item = children[i]
        if item == child:
          after = true
          continue
        if not nodes[item].sigma:
          if after:
            right[rightCount] = item
            inc rightCount
          else:
            left[leftCount] = item
            inc leftCount
      setInterval(nodes[id].leftValid, nodes[id].leftInterval, nodes, left, leftCount)
      setInterval(nodes[id].rightValid, nodes[id].rightInterval, nodes, right, rightCount)
      continue
    nodes[id].kind = 1
    var gaps: array[6, array[5, int]]
    var gapCounts: array[6, int]
    var gap = 0
    for i in 0 ..< childCount:
      let item = children[i]
      if nodes[item].sigma:
        inc gap
      else:
        gaps[gap][gapCounts[gap]] = item
        inc gapCounts[gap]
    nodes[id].gapCount = sigCount + 1
    for g in 0 .. sigCount:
      if gapCounts[g] > 0:
        nodes[id].gapLeft[g] = nodes[gaps[g][0]].saLeft
        nodes[id].gapRight[g] = nodes[gaps[g][gapCounts[g] - 1]].saRight
    for symbol in 0 ..< sigma:
      var found = -1
      var preceding = 0
      for i in 0 ..< sigCount:
        let first = text[nodes[sigmaChildren[i]].edgeStart]
        if first == symbol:
          found = sigmaChildren[i]
          break
        if first < symbol: inc preceding
      if found >= 0:
        nodes[id].childBySymbol[symbol] = found
      elif gapCounts[preceding] > 0:
        nodes[id].groupBySymbol[symbol] = preceding

proc compareSuffixPattern(text: array[MaxSuffixes, int]; textLength, suffixStart: int;
                          pattern: array[MaxPattern, int]; q, startAt: int;
                          lcp: var int): int =
  var i = startAt
  while i < q and suffixStart + i < textLength:
    if text[suffixStart + i] != pattern[i]:
      lcp = i
      return (if text[suffixStart + i] < pattern[i]: -1 else: 1)
    inc i
  lcp = i
  if i == q: return 1
  -1

proc intervalSearch(text: array[MaxSuffixes, int]; textLength: int;
                    pattern: array[MaxPattern, int]; q: int;
                    suffixes: array[MaxSuffixes, int]; lo, hi, knownPrefix: int): int =
  var low = lo - 1
  var high = hi + 1
  var lowLcp = knownPrefix
  var highLcp = knownPrefix
  while high - low > 1:
    let middle = (low + high) div 2
    var lcp = knownPrefix
    let comparison = compareSuffixPattern(text, textLength, suffixes[middle], pattern, q,
                                          min(lowLcp, highLcp), lcp)
    if comparison < 0:
      low = middle
      lowLcp = lcp
    else:
      high = middle
      highLcp = lcp
  if high > hi: return -1
  let start = suffixes[high]
  if start + q > textLength: return -1
  for i in 0 ..< q:
    if text[start + i] != pattern[i]: return -1
  start

proc trayQuery(text: array[MaxSuffixes, int]; textLength: int;
               pattern: array[MaxPattern, int]; q, sigma: int;
               suffixes: array[MaxSuffixes, int]; nodes: openArray[TrayNode]): int =
  var current = 0
  var matched = 0
  while true:
    if matched == q: return suffixes[nodes[current].saLeft]
    let symbol = pattern[matched]
    if not nodes[current].sigma or nodes[current].kind == 3:
      return intervalSearch(text, textLength, pattern, q, suffixes,
                            nodes[current].saLeft, nodes[current].saRight, matched)
    var next = -1
    var intervalLeft = -1
    var intervalRight = -1
    if nodes[current].kind == 1:
      if symbol < 0 or symbol >= sigma: return -1
      next = nodes[current].childBySymbol[symbol]
      if next < 0:
        let group = nodes[current].groupBySymbol[symbol]
        if group < 0 or nodes[current].gapLeft[group] < 0: return -1
        intervalLeft = nodes[current].gapLeft[group]
        intervalRight = nodes[current].gapRight[group]
    else:
      next = nodes[current].onlySigmaChild
      if symbol != nodes[current].separator:
        if symbol < nodes[current].separator:
          if not nodes[current].leftValid: return -1
          intervalLeft = nodes[current].leftInterval[0]
          intervalRight = nodes[current].leftInterval[1]
        else:
          if not nodes[current].rightValid: return -1
          intervalLeft = nodes[current].rightInterval[0]
          intervalRight = nodes[current].rightInterval[1]
    if intervalLeft >= 0:
      return intervalSearch(text, textLength, pattern, q, suffixes,
                            intervalLeft, intervalRight, matched)
    if next < 0: return -1
    let representative = suffixes[nodes[next].saLeft]
    var edgePosition = nodes[current].depth
    while matched < q and edgePosition < nodes[next].depth:
      if text[representative + edgePosition] != pattern[matched]: return -1
      inc matched
      inc edgePosition
    if matched == q: return suffixes[nodes[next].saLeft]
    if edgePosition != nodes[next].depth: return -1
    current = next

proc putI64Le(output: ptr UncheckedArray[uint8]; position: int; value: int64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[position + i] = uint8((bits shr (8 * i)) and 255)

proc suffix_tray_pattern_query*(input: ptr UncheckedArray[int64]; length: csize_t;
    output: ptr UncheckedArray[uint8]; capacity: csize_t): int64 {.cdecl, exportc: "suffix_tray_pattern_query".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let sigmaRaw = input[0]
  let nRaw = input[1]
  let qRaw = input[2]
  if sigmaRaw < 2 or sigmaRaw > MaxSigma or nRaw < 1 or nRaw > MaxText or
      qRaw < 1 or qRaw > MaxPattern: return -1
  let sigma = int(sigmaRaw)
  let n = int(nRaw)
  let q = int(qRaw)
  if int(length) != 3 + n + q: return -1
  var text: array[MaxSuffixes, int]
  var pattern: array[MaxPattern, int]
  for i in 0 ..< n:
    if input[3 + i] < 0 or input[3 + i] >= sigmaRaw: return -1
    text[i] = int(input[3 + i])
  text[n] = -1
  for i in 0 ..< q:
    if input[3 + n + i] < 0 or input[3 + n + i] >= sigmaRaw: return -1
    pattern[i] = int(input[3 + n + i])
  if output.isNil or capacity < csize_t(MaxOutput): return -2
  var suffixes, rank: array[MaxSuffixes, int]
  buildSuffixArray(text, n + 1, suffixes, rank)
  var nodes: array[MaxNodes, TrayNode]
  for i in 0 ..< MaxNodes: initNode(nodes[i], 0, 0, 0, -1)
  var nodeCount = 1
  for start in 0 .. n: insertSuffix(nodes, nodeCount, text, n + 1, start)
  summarizeNode(nodes, 0, rank, sigma)
  buildTray(nodes, nodeCount, sigma, text)
  let found = trayQuery(text, n + 1, pattern, q, sigma, suffixes, nodes)
  putI64Le(output, 0, (if found < 0: 0'i64 else: 1'i64))
  putI64Le(output, 8, int64(found))
  int64(MaxOutput)
