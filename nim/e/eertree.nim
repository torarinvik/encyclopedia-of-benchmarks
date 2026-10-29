const
  MaxTextLength = 128
  MaxNodes = MaxTextLength + 2
  AlphabetSize = 26

type
  EertreeNode = object
    length, suffixLink: int
    next: array[AlphabetSize, int]
  EertreeNodes = array[MaxNodes, EertreeNode]

proc initializeNode(nodes: var EertreeNodes, id, nodeLength, suffixLink: int) =
  nodes[id].length = nodeLength
  nodes[id].suffixLink = suffixLink
  for letter in 0 ..< AlphabetSize:
    nodes[id].next[letter] = -1

proc findExtendable(nodes: var EertreeNodes, text: openArray[int], position, start: int): int =
  result = start
  while true:
    let preceding = position - 1 - nodes[result].length
    if preceding >= 0 and text[preceding] == text[position]: return
    result = nodes[result].suffixLink

proc eertree*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "eertree".} =
  if values == nil or length < 1 or length > csize_t(MaxTextLength + 1): return -1
  if values[0] < 0 or values[0] > int64(MaxTextLength): return -1
  let textLength = int(values[0])
  if length != csize_t(textLength + 1): return -1
  var text: array[MaxTextLength, int]
  for position in 0 ..< textLength:
    if values[position + 1] < 0 or values[position + 1] >= int64(AlphabetSize): return -1
    text[position] = int(values[position + 1])

  var nodes: EertreeNodes
  initializeNode(nodes, 0, -1, 0)
  initializeNode(nodes, 1, 0, 0)
  var nodeCount = 2
  var longestSuffix = 1
  var checksum = 0'i64
  for position in 0 ..< textLength:
    let letter = text[position]
    let parent = findExtendable(nodes, text.toOpenArray(0, textLength - 1), position, longestSuffix)
    var next = nodes[parent].next[letter]
    if next < 0:
      next = nodeCount
      inc nodeCount
      initializeNode(nodes, next, nodes[parent].length + 2, 0)
      nodes[parent].next[letter] = next
      if nodes[next].length == 1:
        nodes[next].suffixLink = 1
      else:
        let suffixParent = findExtendable(nodes, text.toOpenArray(0, textLength - 1),
                                          position, nodes[parent].suffixLink)
        let suffix = nodes[suffixParent].next[letter]
        if suffix < 0: return -1
        nodes[next].suffixLink = suffix
    longestSuffix = next
    checksum += int64(position + 1) * int64(nodeCount - 2)
  checksum
