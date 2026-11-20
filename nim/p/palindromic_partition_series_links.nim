const
  MaxText = 64
  MaxNodes = MaxText + 2
  Alphabet = 4
  MaxWords = MaxText + 1

type
  Node = object
    length, suffixLink, difference, seriesLink, seriesBest, seriesStart: int
    next: array[Alphabet, int]
  Nodes = array[MaxNodes, Node]

proc initializeNode(nodes: var Nodes, id, nodeLength, suffixLink: int) =
  nodes[id].length = nodeLength
  nodes[id].suffixLink = suffixLink
  nodes[id].difference = 0
  nodes[id].seriesLink = 1
  nodes[id].seriesBest = 0
  nodes[id].seriesStart = 0
  for symbol in 0 ..< Alphabet:
    nodes[id].next[symbol] = 0

proc findExtendable(nodes: var Nodes, text: array[MaxText, int], position, start: int): int =
  result = start
  while true:
    let preceding = position - 1 - nodes[result].length
    if preceding >= 0 and text[preceding] == text[position]: return
    result = nodes[result].suffixLink

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc palindromic_partition_series_links*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "palindromic_partition_series_links".} =
  if input.isNil or length < 1 or length > csize_t(MaxText + 2): return -1
  if input[0] < 0 or input[0] > int64(MaxText): return -1
  let n = int(input[0])
  if int(length) != n + 1: return -1
  var text: array[MaxText, int]
  for position in 0 ..< n:
    let symbol = input[position + 1]
    if symbol < 0 or symbol >= int64(Alphabet): return -1
    text[position] = int(symbol)

  var nodes: Nodes
  initializeNode(nodes, 0, 0, 1)
  initializeNode(nodes, 1, -1, 1)
  var nodeCount = 2
  var last = 0
  var dp: array[MaxText + 1, int]
  var predecessor: array[MaxText + 1, int]
  for i in 0 .. MaxText: dp[i] = MaxText + 1
  dp[0] = 0

  for position in 0 ..< n:
    let end = position + 1
    let symbol = text[position]
    let parent = findExtendable(nodes, text, position, last)
    var next = nodes[parent].next[symbol]
    if next == 0:
      next = nodeCount
      inc nodeCount
      initializeNode(nodes, next, nodes[parent].length + 2, 0)
      nodes[parent].next[symbol] = next
      if nodes[next].length == 1:
        nodes[next].suffixLink = 0
      else:
        let suffixParent = findExtendable(nodes, text, position, nodes[parent].suffixLink)
        nodes[next].suffixLink = nodes[suffixParent].next[symbol]
      let fail = nodes[next].suffixLink
      nodes[next].difference = nodes[next].length - nodes[fail].length
      if nodes[next].difference == nodes[fail].difference:
        nodes[next].seriesLink = nodes[fail].seriesLink
      else:
        nodes[next].seriesLink = fail
    last = next

    var bestValue = MaxText + 1
    var bestStart = end
    var node = last
    while nodes[node].length > 0:
      let start = end - nodes[nodes[node].seriesLink].length - nodes[node].difference
      nodes[node].seriesBest = dp[start]
      nodes[node].seriesStart = start
      let fail = nodes[node].suffixLink
      if nodes[node].difference == nodes[fail].difference and
          (nodes[fail].seriesBest < nodes[node].seriesBest or
           nodes[fail].seriesBest == nodes[node].seriesBest and
           nodes[fail].seriesStart < nodes[node].seriesStart):
        nodes[node].seriesBest = nodes[fail].seriesBest
        nodes[node].seriesStart = nodes[fail].seriesStart
      let candidate = nodes[node].seriesBest + 1
      if candidate < bestValue or
          candidate == bestValue and nodes[node].seriesStart < bestStart:
        bestValue = candidate
        bestStart = nodes[node].seriesStart
      node = nodes[node].seriesLink
    dp[end] = bestValue
    predecessor[end] = bestStart

  var reversePieces: array[MaxText, int]
  var pieceCount = 0
  var end = n
  while end > 0:
    reversePieces[pieceCount] = end - predecessor[end]
    inc pieceCount
    end = predecessor[end]
  var words: array[MaxWords, int64]
  var wordCount = 0
  words[wordCount] = int64(pieceCount)
  inc wordCount
  for index in 0 ..< pieceCount:
    words[wordCount] = int64(reversePieces[pieceCount - 1 - index])
    inc wordCount
  let byteCount = wordCount * 8
  if output.isNil or int(capacity) < byteCount: return -2
  for word in 0 ..< wordCount: putI64(output, word * 8, words[word])
  int64(byteCount)
