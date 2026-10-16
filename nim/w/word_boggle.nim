const MaxNodes = 481
const Alphabet = 52
proc validChar(ch: int64): bool = (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)
proc charIndex(ch: int64): int =
  if ch <= 90: int(ch - 65) else: int(ch - 97 + 26)
proc visit(board: ptr UncheckedArray[int64], rows, cols, pos, node: int,
           children: ptr UncheckedArray[int], terminal: ptr UncheckedArray[int],
           visited: ptr UncheckedArray[uint8], found: ptr UncheckedArray[uint8]) =
  visited[pos] = 1
  if terminal[node] >= 0: found[terminal[node]] = 1
  let row = pos div cols; let col = pos mod cols
  for dr in -1 .. 1:
    for dc in -1 .. 1:
      if dr == 0 and dc == 0: continue
      let nr = row + dr; let nc = col + dc
      if nr < 0 or nc < 0 or nr >= rows or nc >= cols: continue
      let next = nr * cols + nc
      if visited[next] != 0: continue
      let child = children[node * Alphabet + charIndex(board[next])]
      if child >= 0: visit(board, rows, cols, next, child, children, terminal, visited, found)
  visited[pos] = 0
proc word_boggle*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "word_boggle".} =
  if input.isNil or length < 3 or length > 550: return -1
  if input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6: return -1
  let rows = int(input[0]); let cols = int(input[1]); let cells = rows * cols; let dictAt = 2 + cells
  if length <= csize_t(dictAt) or input[dictAt] < 0 or input[dictAt] > 32: return -1
  let count = int(input[dictAt])
  for i in 0 ..< cells:
    if not validChar(input[2+i]): return -1
  var words: array[480, int64]; var lens: array[32, int]; var unique = 0; var at = dictAt + 1
  for k in 0 ..< count:
    if at >= int(length) or input[at] < 1 or input[at] > 15: return -1
    let n = int(input[at]); inc at
    if int(length) - at < n: return -1
    var duplicate = false
    for w in 0 ..< unique:
      if lens[w] == n:
        var same = true
        for j in 0 ..< n:
          if words[w*15+j] != input[at+j]: same = false
        if same: duplicate = true
    for j in 0 ..< n:
      if not validChar(input[at+j]): return -1
    if not duplicate:
      lens[unique] = n
      for j in 0 ..< n: words[unique*15+j] = input[at+j]
      inc unique
    at += n
  if at != int(length): return -1
  var children: array[MaxNodes*Alphabet, int]
  for i in 0 ..< children.len: children[i] = -1
  var terminal: array[MaxNodes, int]
  for i in 0 ..< terminal.len: terminal[i] = -1
  var nodes = 1
  for w in 0 ..< unique:
    var node = 0
    for j in 0 ..< lens[w]:
      let slot = node*Alphabet + charIndex(words[w*15+j])
      if children[slot] < 0: children[slot] = nodes; inc nodes
      node = children[slot]
    terminal[node] = w
  var found: array[32, uint8]; var visited: array[36, uint8]
  for p in 0 ..< cells:
    let child = children[charIndex(input[2+p])]
    if child >= 0: visit(cast[ptr UncheckedArray[int64]](addr input[2]), rows, cols, p, child, cast[ptr UncheckedArray[int]](addr children[0]), cast[ptr UncheckedArray[int]](addr terminal[0]), cast[ptr UncheckedArray[uint8]](addr visited[0]), cast[ptr UncheckedArray[uint8]](addr found[0]))
  var order: array[32, int]; var foundCount = 0; var outputSize = 0
  for w in 0 ..< unique:
    if found[w] != 0:
      order[foundCount] = w
      inc foundCount
      outputSize += lens[w] + 1
  for i in 1 ..< foundCount:
    let value = order[i]; var j = i
    while j > 0:
      let prev = order[j-1]; var less = false; var decided = false
      for b in 0 ..< min(lens[value], lens[prev]):
        if words[value*15+b] != words[prev*15+b]: less = words[value*15+b] < words[prev*15+b]; decided = true; break
      if not decided: less = lens[value] < lens[prev]
      if not less: break
      order[j] = prev; dec j
    order[j] = value
  if capacity < csize_t(outputSize) or (output.isNil and outputSize > 0): return -2
  var pos = 0
  for k in 0 ..< foundCount:
    let w = order[k]
    for j in 0 ..< lens[w]: output[pos] = uint8(words[w*15+j]); inc pos
    output[pos] = 0; inc pos
  int64(outputSize)
