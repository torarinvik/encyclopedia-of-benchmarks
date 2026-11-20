const MaxN = 31
const MaxQ = 32
const MaxInput = 129
const MaxBits = 2 * MaxN
const MaxOutputWords = 4 + MaxQ

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc bp_ordered_tree_navigation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bp_ordered_tree_navigation".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  let bitLength = 2 * n
  if length != csize_t(2 + (n - 1) + 3 * q): return -1

  var parent: array[MaxN, int]
  for vertex in 1 ..< n:
    let value = input[1 + vertex]
    if value < 0 or value >= int64(vertex): return -1
    parent[vertex] = int(value)
  let queryBase = n + 1
  for index in 0 ..< q:
    let offset = queryBase + 3 * index
    let opcode = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if opcode == 0 or opcode == 1:
      if first < 0 or first > int64(bitLength) or second < -int64(bitLength) or second > int64(bitLength): return -1
    elif opcode == 2:
      if first < 0 or second < first or second >= int64(bitLength): return -1
    elif opcode == 3 or opcode == 4 or opcode == 5:
      if first < 0 or first >= int64(bitLength) or second != 0: return -1
    else: return -1

  var bits: array[MaxBits, int]
  var stackNode, nextChild: array[MaxN + 1, int]
  var bitCount = 1
  var depth = 1
  bits[0] = 1
  nextChild[0] = 1
  while depth > 0:
    let frame = depth - 1
    let node = stackNode[frame]
    var child = nextChild[frame]
    while child < n and parent[child] != node: inc child
    if child < n:
      nextChild[frame] = child + 1
      bits[bitCount] = 1
      inc bitCount
      stackNode[depth] = child
      nextChild[depth] = 1
      inc depth
    else:
      bits[bitCount] = 0
      inc bitCount
      dec depth
  if bitCount != bitLength: return -1

  var excess: array[MaxBits + 1, int64]
  var packed: uint64 = 0
  for position in 0 ..< bitLength:
    if bits[position] != 0:
      packed = packed or (1'u64 shl position)
      excess[position + 1] = excess[position] + 1
    else:
      excess[position + 1] = excess[position] - 1
  for index in 0 ..< q:
    let offset = queryBase + 3 * index
    let opcode = input[offset]
    let first = int(input[offset + 1])
    if opcode == 3 and bits[first] == 0: return -1
    if opcode == 4 and bits[first] != 0: return -1
    if opcode == 5 and bits[first] == 0: return -1

  var words: array[MaxOutputWords, int64]
  words[0] = nValue
  words[1] = int64(bitLength)
  words[2] = int64(packed)
  words[3] = qValue
  for index in 0 ..< q:
    let offset = queryBase + 3 * index
    let opcode = input[offset]
    let first = int(input[offset + 1])
    let second = input[offset + 2]
    var answer: int64 = -1
    if opcode == 0 or opcode == 1:
      let target = excess[first] + second
      if opcode == 0:
        answer = int64(bitLength + 1)
        for position in (first + 1) .. bitLength:
          if excess[position] == target:
            answer = int64(position)
            break
      else:
        answer = 0
        var position = first
        while position > 0:
          dec position
          if excess[position] == target:
            answer = int64(position)
            break
    elif opcode == 2:
      let right = int(second)
      var best = first
      for position in (first + 1) .. right:
        if excess[position + 1] < excess[best + 1]: best = position
      answer = int64(best)
    elif opcode == 3:
      let target = excess[first + 1] - 1
      for position in (first + 2) .. bitLength:
        if excess[position] == target:
          answer = int64(position - 1)
          break
    elif opcode == 4:
      let target = excess[first + 1]
      var position = first + 1
      while position > 0:
        dec position
        if excess[position] == target:
          answer = int64(position)
          break
    elif first == 0:
      answer = -1
    else:
      let target = excess[first + 1] - 2
      var position = first + 1
      while position > 0:
        dec position
        if excess[position] == target:
          answer = int64(position)
          break
    words[4 + index] = answer

  let outputWords = 4 + q
  let required = 8 * outputWords
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< outputWords:
    writeI64Le(output, 8 * index, words[index])
  int64(required)
