const MaxText = 16
const MaxParens = 8
const MaxRows = 1 shl MaxParens
const MaxOutput = 4354

proc balanced(text: array[MaxText, uint8], n: int): bool =
  var depth = 0
  for i in 0 ..< n:
    if text[i] == uint8('('): inc depth
    elif text[i] == uint8(')'):
      dec depth
      if depth < 0: return false
  depth == 0

proc lessRow(a: array[MaxText, uint8], al: int, b: array[MaxText, uint8], bl: int): bool =
  let common = min(al, bl)
  for i in 0 ..< common:
    if a[i] != b[i]: return a[i] < b[i]
  al < bl

proc minimum_parenthesis_removal_bfs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "minimum_parenthesis_removal_bfs".} =
  if input == nil or length < csize_t(1) or length > csize_t(MaxText + 1): return -1
  let nArg = input[0]
  if nArg < 0 or nArg > MaxText or length != csize_t(nArg + 1): return -1
  let n = int(nArg)
  var text: array[MaxText, uint8]
  var positions: array[MaxParens, int]
  var p = 0
  for i in 0 ..< n:
    let value = input[i + 1]
    if value == 40 or value == 41:
      if p == MaxParens: return -1
      positions[p] = i
      inc p
    elif value < 97 or value > 122: return -1
    text[i] = uint8(value)
  var rows: array[MaxRows, array[MaxText, uint8]]
  var sizes: array[MaxRows, uint8]
  var count = 0
  let states = 1 shl p
  for deletions in 0 .. p:
    for mask in 0 ..< states:
      if countBits(mask) != deletions: continue
      var candidate: array[MaxText, uint8]
      var used = 0
      var ordinal = 0
      for i in 0 ..< n:
        let atParen = ordinal < p and positions[ordinal] == i
        let remove = atParen and (mask and (1 shl ordinal)) != 0
        if atParen: inc ordinal
        if not remove:
          candidate[used] = text[i]
          inc used
      if not balanced(candidate, used): continue
      var duplicate = false
      for r in 0 ..< count:
        if int(sizes[r]) == used:
          var same = true
          for j in 0 ..< used:
            if rows[r][j] != candidate[j]: same = false
          if same: duplicate = true
      if not duplicate:
        rows[count] = candidate
        sizes[count] = uint8(used)
        inc count
    if count != 0: break
  if count == 0:
    rows[0][0] = 0
    sizes[0] = 0
    count = 1
  for i in 1 ..< count:
    let key = rows[i]
    let keyLen = int(sizes[i])
    var j = i
    while j > 0 and lessRow(key, keyLen, rows[j - 1], int(sizes[j - 1])):
      rows[j] = rows[j - 1]
      sizes[j] = sizes[j - 1]
      dec j
    rows[j] = key
    sizes[j] = uint8(keyLen)
  var needed = 2
  for r in 0 ..< count: needed += 1 + int(sizes[r])
  if needed > MaxOutput: return -1
  if output == nil or capacity < csize_t(needed): return -2
  output[0] = uint8(count and 255)
  output[1] = uint8((count shr 8) and 255)
  var pos = 2
  for r in 0 ..< count:
    let rowLen = int(sizes[r])
    output[pos] = uint8(rowLen)
    inc pos
    for j in 0 ..< rowLen:
      output[pos] = rows[r][j]
      inc pos
  int64(pos)

proc countBits(value: int): int =
  var x = value
  while x != 0:
    result += x and 1
    x = x shr 1
