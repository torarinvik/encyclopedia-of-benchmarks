const MaxTaxa = 7
const MaxTriplets = 105
const MaxNodes = 13

proc storeWord(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc aho_build_rooted_triplet_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "aho_build_rooted_triplet_tree".} =
  if input == nil or length < 2 or length > 318: return -1
  if input[0] < 1 or input[0] > MaxTaxa or input[1] < 0: return -1
  let n = int(input[0])
  let qLimit = n * (n - 1) * (n - 2) div 2
  if input[1] > qLimit: return -1
  let q = int(input[1])
  if int(length) != 2 + 3 * q: return -1

  var triples: array[MaxTriplets, array[3, int]]
  for i in 0 ..< q:
    let a0 = input[2 + 3 * i]
    let b0 = input[3 + 3 * i]
    let c0 = input[4 + 3 * i]
    if a0 < 0 or a0 >= n or b0 < 0 or b0 >= n or c0 < 0 or c0 >= n or a0 == b0 or a0 == c0 or b0 == c0: return -1
    var a = int(a0)
    var b = int(b0)
    if a > b: swap(a, b)
    for j in 0 ..< i:
      if triples[j][0] == a and triples[j][1] == b and triples[j][2] == int(c0): return -1
    triples[i] = [a, b, int(c0)]

  var kind: array[MaxNodes, int]
  var nodeValue: array[MaxNodes, int]
  var tasks: array[MaxNodes, int]
  tasks[0] = (1 shl n) - 1
  var top = 1
  var nodeCount = 0
  var compatible = true
  while top > 0:
    dec top
    let mask = tasks[top]
    if (mask and (mask - 1)) == 0:
      var label = 0
      while (mask and (1 shl label)) == 0: inc label
      kind[nodeCount] = 1
      nodeValue[nodeCount] = label
      inc nodeCount
      continue
    var edge: array[MaxTaxa, array[MaxTaxa, bool]]
    for t in 0 ..< q:
      let a = triples[t][0]
      let b = triples[t][1]
      let c = triples[t][2]
      let needed = (1 shl a) or (1 shl b) or (1 shl c)
      if (mask and needed) == needed:
        edge[a][b] = true
        edge[b][a] = true
    var seen: array[MaxTaxa, bool]
    var components: array[MaxTaxa, int]
    var componentCount = 0
    for start in 0 ..< n:
      if (mask and (1 shl start)) == 0 or seen[start]: continue
      var queue: array[MaxTaxa, int]
      var head = 0
      var tail = 1
      var component = 0
      queue[0] = start
      seen[start] = true
      while head < tail:
        let current = queue[head]
        inc head
        component = component or (1 shl current)
        for other in 0 ..< n:
          if edge[current][other] and not seen[other]:
            seen[other] = true
            queue[tail] = other
            inc tail
      components[componentCount] = component
      inc componentCount
    if componentCount == 1:
      compatible = false
      break
    kind[nodeCount] = 0
    nodeValue[nodeCount] = componentCount
    inc nodeCount
    var index = componentCount
    while index > 0:
      dec index
      tasks[top] = components[index]
      inc top

  var words: array[MaxNodes + 1, int64]
  var wordCount = 1
  if compatible:
    words[0] = int64(nodeCount)
    for i in 0 ..< nodeCount:
      if kind[i] == 1: words[i + 1] = -int64(nodeValue[i] + 1)
      else: words[i + 1] = int64(nodeValue[i])
    wordCount += nodeCount
  else:
    words[0] = 0
  let bytes = wordCount * 8
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for i in 0 ..< wordCount: storeWord(output, i * 8, words[i])
  int64(bytes)
