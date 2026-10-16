proc detecting_english_programmatically*(a: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc.} =
  if a == nil or n < 1 or n > 172: return -1
  let length = int(n)
  var p = 0
  let count = a[p]; inc p
  if count < 0 or count > 8: return -1
  var starts: array[8, int]
  var lens: array[8, int]
  for w in 0 ..< int(count):
    if p >= length: return -1
    let l = a[p]; inc p
    if l < 1 or l > 12 or p + int(l) > length: return -1
    starts[w] = p; lens[w] = int(l)
    for j in 0 ..< int(l):
      if a[p+j] < 65 or a[p+j] > 90: return -1
    if w > 0:
      var k = 0
      while k < lens[w-1] and k < lens[w] and a[starts[w-1]+k] == a[p+k]: inc k
      if k == lens[w-1] and k == lens[w]: return -1
      if k == lens[w-1] and k < lens[w]: discard
      elif k < lens[w-1] and k < lens[w] and a[starts[w-1]+k] > a[p+k]: return -1
      elif k < lens[w-1] and k == lens[w]: return -1
    p += int(l)
  if p >= length: return -1
  let m = a[p]; inc p
  if m < 1 or m > 64 or p + int(m) + 2 != length: return -1
  let ms = p
  for j in 0 ..< int(m):
    if a[ms+j] < 0 or a[ms+j] > 127: return -1
  p += int(m)
  let wp = a[p]; let lp = a[p+1]
  if wp < 0 or wp > 100 or lp < 0 or lp > 100: return -1
  var retained = 0; var tokens = 0; var hits = 0; var i = 0
  var token: array[64, int64]; var tokLen = 0
  while i <= int(m):
    var c = if i < int(m): a[ms+i] else: 32'i64
    let letter = (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
    let ws = c == 9 or c == 10 or c == 32
    if i < int(m) and (letter or ws): inc retained
    if letter:
      token[tokLen] = if c >= 97: c - 32 else: c
      inc tokLen; inc i; continue
    if not ws: inc i; continue
    if tokLen == 0: inc i; continue
    inc tokens
    for w in 0 ..< int(count):
      if lens[w] != tokLen: continue
      var k = 0
      while k < tokLen and a[starts[w]+k] == token[k]: inc k
      if k == tokLen: inc hits; break
    tokLen = 0; inc i
  if tokens > 0 and hits * 100 >= wp * tokens and int64(retained) * 100 >= lp * m: return 1
  return 0
