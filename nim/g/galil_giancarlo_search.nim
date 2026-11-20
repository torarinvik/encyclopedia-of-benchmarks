type I64Input = ptr UncheckedArray[int64]

const MaxText = 4096
const MaxPattern = 128
const MaxInput = 4227
const Tables = 130

proc preprocess(pattern: openArray[int64], m: int, order, nextPos, shift: var array[Tables,int64]): int64 =
  var hmax, kmin, prefix, rmin: array[Tables,int64]
  var i = 1'i64
  var k = 1'i64
  while k <= int64(m):
    while pattern[int(i)] == pattern[int(i-k)]: inc i
    hmax[int(k)] = i
    var q = k + 1
    while hmax[int(q-k)] + k < i:
      hmax[int(q)] = hmax[int(q-k)] + k
      inc q
    k = q
    if k == i + 1: i = k
  for x in countdown(m, 1):
    if hmax[x] < int64(m): kmin[int(hmax[x])] = int64(x)
  var r = int64(m)
  for x in countdown(m-1, 0):
    if hmax[x+1] == int64(m): r = int64(x+1)
    if kmin[x] == 0: rmin[x] = r
  var split = -1
  r = int64(m)
  for x in 0 ..< m:
    if kmin[x] == 0:
      dec r
      order[int(r)] = int64(x)
    else:
      inc split
      order[split] = int64(x)
  for x in 0 .. split: shift[x] = kmin[int(order[x])]
  for x in split+1 ..< m: shift[x] = rmin[int(order[x])]
  shift[m] = rmin[0]
  var count = 0'i64
  for x in 0 ..< m:
    prefix[x] = count
    if kmin[x] > 0: inc count
  for x in 0 .. split: nextPos[x] = prefix[int(order[x]-kmin[int(order[x])])]
  for x in split+1 ..< m: nextPos[x] = prefix[m-int(rmin[int(order[x])])]
  nextPos[m] = prefix[m-int(rmin[int(order[m-1])])]
  int64(split)

proc search(text, pattern: openArray[int64], n, m: int): int64 =
  var ell = 0
  while ell+1 < m and pattern[ell+1] == pattern[0]: inc ell
  var matches = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  if ell == m-1:
    var run = 0
    for position in 0 ..< n:
      if text[position] == pattern[0]: inc run else: run = 0
      if run >= m:
        let start = int64(position+1-m)
        inc matches
        offsetSum += start
        offsetXor = offsetXor xor start
    return (matches shl 36) or (offsetSum shl 12) or offsetXor
  var order, nextPos, shift: array[Tables,int64]
  let nd = preprocess(pattern,m,order,nextPos,shift)
  if n < m: return 0
  var i = 0'i64
  var j = 0'i64
  var last = -1'i64
  var heavy = false
  while j <= int64(n-m):
    if heavy and i == 0:
      var k = last-j+1
      while j+k < int64(n) and pattern[0] == text[int(j+k)]: inc k
      if k <= int64(ell) or j+k >= int64(n) or pattern[ell+1] != text[int(j+k)]:
        i = 0; j += k+1; last = j-1
      else:
        i = 1; last = j+k; j = last-int64(ell+1)
    else:
      while i < int64(m) and last < j+order[int(i)] and
          pattern[int(order[int(i)])] == text[int(j+order[int(i)])]: inc i
      if i >= int64(m) or last >= j+order[int(i)]:
        inc matches
        offsetSum += j
        offsetXor = offsetXor xor j
        i = int64(m)
      if i > nd: last = j+int64(m)-1
      j += shift[int(i)]
      i = nextPos[int(i)]
    heavy = j <= last
  (matches shl 36) or (offsetSum shl 12) or offsetXor

proc galil_giancarlo_search*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "galil_giancarlo_search".} =
  if input == nil or length < 2 or length > MaxInput: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 0 or nValue > MaxText or mValue < 1 or mValue > MaxPattern: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2+n+m): return -1
  var text: array[MaxText,int64]
  var pattern: array[Tables,int64]
  for i in 0 ..< n:
    let symbol = input[2+i]
    if symbol < 0 or symbol > 3: return -1
    text[i] = symbol
  for i in 0 ..< m:
    let symbol = input[2+n+i]
    if symbol < 0 or symbol > 3: return -1
    pattern[i] = symbol
  pattern[m] = 4
  search(text,pattern,n,m)
