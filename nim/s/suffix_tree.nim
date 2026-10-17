const MaxTextLength = 64
const MaxNodes = 1 + 2 * MaxTextLength
const MaxEdges = 2 * MaxTextLength
const MaxOutputBytes = 5176

proc appendEdge(parent, child: int, firstEdge, lastEdge: var array[MaxNodes, int],
    edgeChild, edgeNext: var array[MaxEdges, int], edgeCount: var int) =
  let edge = edgeCount
  inc edgeCount
  edgeChild[edge] = child
  edgeNext[edge] = -1
  if lastEdge[parent] < 0:
    firstEdge[parent] = edge
  else:
    edgeNext[lastEdge[parent]] = edge
  lastEdge[parent] = edge

proc writeU64(output: var array[MaxOutputBytes, uint8], position: var int, value: uint64) =
  for shift in 0 ..< 8:
    output[position] = uint8((value shr (shift * 8)) and 0xff'u64)
    inc position

proc suffix_tree_construct*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "suffix_tree_construct".} =
  if input == nil or inputLength < 1 or inputLength > csize_t(66): return -1
  let textLengthValue = input[0]
  if textLengthValue < 0 or textLengthValue > MaxTextLength.int64: return -1
  let textLength = int(textLengthValue)
  if inputLength != csize_t(1 + textLength): return -1
  var text: array[MaxTextLength, uint8]
  for index in 0 ..< textLength:
    let code = input[1 + index]
    if code < 0 or code > 127: return -1
    text[index] = uint8(code)

  var labels: array[MaxNodes, array[MaxTextLength, uint8]]
  var labelLengths: array[MaxNodes, int]
  var firstEdge, lastEdge: array[MaxNodes, int]
  var edgeChild, edgeNext: array[MaxEdges, int]
  for i in 0 ..< MaxNodes:
    firstEdge[i] = -1
    lastEdge[i] = -1
  for i in 0 ..< MaxEdges: edgeNext[i] = -1
  var nodeCount = 1
  var edgeCount = 0

  for start in 0 ..< textLength:
    let suffixLength = textLength - start
    var offset = 0
    var node = 0
    while offset < suffixLength:
      let firstCode = text[start + offset]
      var selected = firstEdge[node]
      while selected >= 0 and labels[edgeChild[selected]][0] != firstCode:
        selected = edgeNext[selected]
      if selected < 0:
        let leaf = nodeCount
        inc nodeCount
        let leafLength = suffixLength - offset
        for i in 0 ..< leafLength: labels[leaf][i] = text[start + offset + i]
        labelLengths[leaf] = leafLength
        appendEdge(node, leaf, firstEdge, lastEdge, edgeChild, edgeNext, edgeCount)
        break

      let child = edgeChild[selected]
      let childLength = labelLengths[child]
      var common = 0
      while common < childLength and offset + common < suffixLength and
          labels[child][common] == text[start + offset + common]:
        inc common
      if common == childLength:
        offset += common
        node = child
        continue

      let split = nodeCount
      inc nodeCount
      for i in 0 ..< common: labels[split][i] = labels[child][i]
      labelLengths[split] = common
      let remainderLength = childLength - common
      for i in 0 ..< remainderLength: labels[child][i] = labels[child][common + i]
      labelLengths[child] = remainderLength
      edgeChild[selected] = split
      appendEdge(split, child, firstEdge, lastEdge, edgeChild, edgeNext, edgeCount)
      offset += common
      node = split

  var bytes: array[MaxOutputBytes, uint8]
  var written = 0
  writeU64(bytes, written, uint64(nodeCount))
  for node in 0 ..< nodeCount:
    let labelLength = labelLengths[node]
    writeU64(bytes, written, uint64(labelLength))
    for i in 0 ..< labelLength:
      bytes[written] = labels[node][i]
      inc written
    var childCount = 0'u64
    var edge = firstEdge[node]
    while edge >= 0:
      inc childCount
      edge = edgeNext[edge]
    writeU64(bytes, written, childCount)
    edge = firstEdge[node]
    while edge >= 0:
      writeU64(bytes, written, uint64(edgeChild[edge]))
      edge = edgeNext[edge]
  if output == nil or outputCapacity < csize_t(written): return -2
  for i in 0 ..< written: output[i] = bytes[i]
  int64(written)
