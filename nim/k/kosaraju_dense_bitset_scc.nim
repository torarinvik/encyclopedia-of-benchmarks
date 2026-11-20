const
  MaxVertices = 256
  MaxWords = 4
  MaxCells = MaxVertices * MaxWords
  MaxParseableInputLength = 1026

proc lowestBitIndex(bits: uint64): int =
  var value = bits
  result = 0
  while (value and 1'u64) == 0'u64:
    value = value shr 1
    inc result

proc writeU16Le(output: ptr UncheckedArray[uint8], position: int, value: uint16) =
  output[position] = uint8(value and 0xff'u16)
  output[position + 1] = uint8(value shr 8)

proc kosaraju_dense_bitset_scc*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "kosaraju_dense_bitset_scc".} =
  if input.isNil or length < 1 or length > MaxParseableInputLength.csize_t: return -1
  if input[0] < 1'i64 or input[0] > MaxVertices.int64: return -1
  let n = int(input[0])
  let words = (n + 63) div 64
  if int(length) != 1 + n * words: return -1

  var adjacency: array[MaxCells, uint64]
  var transpose: array[MaxCells, uint64]
  for cell in 0 ..< n * words:
    adjacency[cell] = cast[uint64](input[1 + cell])
  if (n mod 64) != 0:
    let valid = (1'u64 shl (n mod 64)) - 1'u64
    for vertex in 0 ..< n:
      if (adjacency[vertex * words + words - 1] and not valid) != 0'u64: return -1
  for source in 0 ..< n:
    for word in 0 ..< words:
      var bits = adjacency[source * words + word]
      while bits != 0'u64:
        let bit = lowestBitIndex(bits)
        let target = word * 64 + bit
        transpose[target * words + source div 64] = transpose[target * words + source div 64] or
          (1'u64 shl (source mod 64))
        bits = bits and (bits - 1'u64)

  var unvisited: array[MaxWords, uint64]
  for word in 0 ..< words: unvisited[word] = high(uint64)
  if (n mod 64) != 0: unvisited[words - 1] = (1'u64 shl (n mod 64)) - 1'u64
  var stack, nextWord, order: array[MaxVertices, uint16]
  var orderLength = 0
  for root in 0 ..< n:
    let rootWord = root div 64
    let rootBit = root mod 64
    if ((unvisited[rootWord] shr rootBit) and 1'u64) == 0'u64: continue
    unvisited[rootWord] = unvisited[rootWord] and not (1'u64 shl rootBit)
    var stackLength = 1
    stack[0] = uint16(root)
    nextWord[0] = 0
    while stackLength != 0:
      let depth = stackLength - 1
      let vertex = int(stack[depth])
      var pushed = false
      while int(nextWord[depth]) < words:
        let word = int(nextWord[depth])
        let candidates = adjacency[vertex * words + word] and unvisited[word]
        if candidates != 0'u64:
          let bit = lowestBitIndex(candidates)
          let neighbor = word * 64 + bit
          unvisited[word] = unvisited[word] and not (1'u64 shl bit)
          stack[stackLength] = uint16(neighbor)
          nextWord[stackLength] = 0
          inc stackLength
          pushed = true
          break
        inc nextWord[depth]
      if not pushed and int(nextWord[depth]) == words:
        order[orderLength] = uint16(vertex)
        inc orderLength
        dec stackLength

  for word in 0 ..< words: unvisited[word] = high(uint64)
  if (n mod 64) != 0: unvisited[words - 1] = (1'u64 shl (n mod 64)) - 1'u64
  var rawComponent: array[MaxVertices, uint16]
  var componentCount: uint16 = 0
  while orderLength != 0:
    dec orderLength
    let root = int(order[orderLength])
    let rootWord = root div 64
    let rootBit = root mod 64
    if ((unvisited[rootWord] shr rootBit) and 1'u64) == 0'u64: continue
    unvisited[rootWord] = unvisited[rootWord] and not (1'u64 shl rootBit)
    var stackLength = 1
    stack[0] = uint16(root)
    rawComponent[root] = componentCount
    while stackLength != 0:
      dec stackLength
      let vertex = int(stack[stackLength])
      for word in 0 ..< words:
        var candidates = transpose[vertex * words + word] and unvisited[word]
        while candidates != 0'u64:
          let bit = lowestBitIndex(candidates)
          let neighbor = word * 64 + bit
          let selected = 1'u64 shl bit
          unvisited[word] = unvisited[word] and not selected
          candidates = candidates and not selected
          rawComponent[neighbor] = componentCount
          stack[stackLength] = uint16(neighbor)
          inc stackLength
    inc componentCount

  var remap: array[MaxVertices, uint16]
  for component in 0 ..< MaxVertices: remap[component] = high(uint16)
  var canonicalCount: uint16 = 0
  for vertex in 0 ..< n:
    let raw = int(rawComponent[vertex])
    if remap[raw] == high(uint16):
      remap[raw] = canonicalCount
      inc canonicalCount
  let outputLength = 2 + 2 * n
  if output.isNil or outputCapacity < csize_t(outputLength): return -2
  writeU16Le(output, 0, canonicalCount)
  for vertex in 0 ..< n:
    writeU16Le(output, 2 + 2 * vertex, remap[int(rawComponent[vertex])])
  int64(outputLength)
