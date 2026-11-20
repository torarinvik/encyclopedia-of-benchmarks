const MaxNodes = 32
const MaxPointer = 64
const RecordWords = 21

proc field(values: ptr UncheckedArray[int64], base, node, offset: int): int64 =
  values[base + node * RecordWords + offset]

proc json_pointer_evaluation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "json_pointer_evaluation".} =
  if values.isNil or length < 3: return -1
  let nValue = values[0]
  let rootValue = values[1]
  let pointerValue = values[2]
  if nValue < 1 or nValue > MaxNodes or rootValue < 0 or rootValue >= nValue or
      pointerValue < 0 or pointerValue > MaxPointer: return -1
  let n = int(nValue)
  let root = int(rootValue)
  let pointerLength = int(pointerValue)
  let base = 3 + pointerLength
  if int(length) != base + n * RecordWords: return -1
  for i in 0 ..< pointerLength:
    if values[3 + i] < 0 or values[3 + i] > 127: return -1
  if pointerLength != 0 and values[3] != ord('/').int64: return -1
  var syntaxPos = 1
  while syntaxPos < pointerLength:
    if values[3 + syntaxPos] == ord('~').int64:
      inc syntaxPos
      if syntaxPos >= pointerLength: return -1
      let escaped = values[3 + syntaxPos]
      if escaped != ord('0').int64 and escaped != ord('1').int64: return -1
    inc syntaxPos

  for i in 0 ..< n:
    let kind = field(values, base, i, 0)
    let parent = field(values, base, i, 1)
    let keyLength = field(values, base, i, 2)
    let arrayIndex = field(values, base, i, 19)
    if kind < 0 or kind > 2 or keyLength < 0 or keyLength > 16: return -1
    if i == root:
      if parent != -1 or keyLength != 0 or arrayIndex != -1: return -1
    else:
      if parent < 0 or parent >= nValue or int(parent) == i: return -1
      let parentKind = field(values, base, int(parent), 0)
      if parentKind < 0 or parentKind > 1: return -1
      if parentKind == 0:
        if arrayIndex != -1: return -1
      elif keyLength != 0 or arrayIndex < 0: return -1
    for k in 0 ..< 16:
      let ch = field(values, base, i, 3 + k)
      if k < int(keyLength):
        if ch < 0 or ch > 127: return -1
      elif ch != 0: return -1
    var cursor = i
    var hops = 0
    while cursor != root and hops < n:
      let next = field(values, base, cursor, 1)
      if next < 0 or next >= nValue: return -1
      cursor = int(next)
      inc hops
    if cursor != root: return -1

  for parent in 0 ..< n:
    if field(values, base, parent, 0) != 1: continue
    var children = 0
    for child in 0 ..< n:
      if field(values, base, child, 1) == int64(parent): inc children
    for child in 0 ..< n:
      if field(values, base, child, 1) != int64(parent): continue
      let index = field(values, base, child, 19)
      if index < 0 or index >= int64(children): return -1
      for prior in 0 ..< child:
        if field(values, base, prior, 1) == int64(parent) and
            field(values, base, prior, 19) == index: return -1

  var current = root
  if pointerLength == 0: return int64(current)
  var token: array[MaxPointer, int64]
  var tokenLength = 0
  var pos = 1
  while pos <= pointerLength:
    if pos == pointerLength or values[3 + pos] == ord('/').int64:
      let kind = field(values, base, current, 0)
      var found = n
      var matches = 0
      if kind == 0:
        for child in 0 ..< n:
          if field(values, base, child, 1) != int64(current) or
              field(values, base, child, 2) != int64(tokenLength): continue
          var k = 0
          while k < tokenLength and field(values, base, child, 3 + k) == token[k]: inc k
          if k == tokenLength:
            found = child
            inc matches
      elif kind == 1:
        if tokenLength == 0 or (tokenLength > 1 and token[0] == ord('0').int64): return -2
        var index = 0'i64
        for k in 0 ..< tokenLength:
          if token[k] < ord('0').int64 or token[k] > ord('9').int64: return -2
          index = index * 10 + token[k] - ord('0').int64
          if index > MaxNodes: return -2
        for child in 0 ..< n:
          if field(values, base, child, 1) == int64(current) and
              field(values, base, child, 19) == index:
            found = child
            inc matches
      else: return -2
      if matches != 1: return -2
      current = found
      tokenLength = 0
      inc pos
      continue
    var ch = values[3 + pos]
    if ch == ord('~').int64:
      inc pos
      if pos >= pointerLength: return -1
      let escaped = values[3 + pos]
      if escaped == ord('0').int64: ch = ord('~').int64
      elif escaped == ord('1').int64: ch = ord('/').int64
      else: return -1
    token[tokenLength] = ch
    inc tokenLength
    inc pos
  int64(current)
