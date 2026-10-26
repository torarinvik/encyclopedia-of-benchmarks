const MaxN = 32
const MaxM = 16
const MaxInput = 50
const MaxOutput = 264

proc suffixCmp(text: array[MaxN, int64], a, b, n: int): int =
  var k = 0
  while a + k < n and b + k < n:
    if text[a + k] < text[b + k]: return -1
    if text[a + k] > text[b + k]: return 1
    inc k
  if a + k == n and b + k == n: return 0
  if a + k == n: return -1
  1

proc patternCmp(text: array[MaxN, int64], start, n: int,
    pattern: array[MaxM, int64], m, offset: int, prefixEqual: bool,
    matched: var int): int =
  matched = offset
  while matched < m and start + matched < n and text[start + matched] == pattern[matched]:
    inc matched
  if matched == m:
    if prefixEqual or start + matched == n: return 0
    return 1
  if start + matched == n: return -1
  if text[start + matched] < pattern[matched]: return -1
  1

proc buildIntervals(n: int, lcp: array[MaxN, int],
    leftQ, rightQ: var array[MaxN * MaxN, int]) =
  var loStack, hiStack: array[MaxN * 2, int]
  var top = 1
  loStack[0] = 0
  hiStack[0] = n - 1
  while top > 0:
    dec top
    let lo = loStack[top]
    let hi = hiStack[top]
    if hi - lo < 2: continue
    let mid = (lo + hi + 1) div 2
    var q = n + 1
    for k in lo ..< mid:
      if lcp[k] < q: q = lcp[k]
    leftQ[lo * MaxN + hi] = q
    q = n + 1
    for k in mid ..< hi:
      if lcp[k] < q: q = lcp[k]
    rightQ[lo * MaxN + hi] = q
    if hi - mid >= 2:
      loStack[top] = mid
      hiStack[top] = hi
      inc top
    if mid - lo >= 2:
      loStack[top] = lo
      hiStack[top] = mid
      inc top

proc bound(text: array[MaxN, int64], n: int,
    pattern: array[MaxM, int64], m: int, suffix: array[MaxN, int],
    leftQ, rightQ: array[MaxN * MaxN, int], prefixEqual: bool): int =
  var l = 0
  var r = 0
  let first = patternCmp(text, suffix[0], n, pattern, m, 0, prefixEqual, l)
  if first > 0 or (not prefixEqual and first == 0): return 0
  let last = patternCmp(text, suffix[n - 1], n, pattern, m, 0, prefixEqual, r)
  if last < 0 or (prefixEqual and last == 0): return n
  var lo = 0
  var hi = n - 1
  while hi - lo > 1:
    let mid = (lo + hi + 1) div 2
    var cmp = 0
    var matched = 0
    if l == r:
      cmp = patternCmp(text, suffix[mid], n, pattern, m, l, prefixEqual, matched)
      if cmp > 0 or (not prefixEqual and cmp == 0):
        hi = mid
        r = matched
      else:
        lo = mid
        l = matched
    elif l > r:
      let q = leftQ[lo * MaxN + hi]
      if l < q:
        lo = mid
      elif l > q:
        hi = mid
        r = q
      else:
        cmp = patternCmp(text, suffix[mid], n, pattern, m, l, prefixEqual, matched)
        if cmp > 0 or (not prefixEqual and cmp == 0):
          hi = mid
          r = matched
        else:
          lo = mid
          l = matched
    else:
      let q = rightQ[lo * MaxN + hi]
      if r < q:
        hi = mid
      elif r > q:
        lo = mid
        l = q
      else:
        cmp = patternCmp(text, suffix[mid], n, pattern, m, r, prefixEqual, matched)
        if cmp > 0 or (not prefixEqual and cmp == 0):
          hi = mid
          r = matched
        else:
          lo = mid
          l = matched
  hi

proc suffix_array_lcp_search*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "suffix_array_lcp_search".} =
  if values == nil or length < 3 or length > csize_t(MaxInput): return -1
  if values[0] < 1 or values[0] > int64(MaxN): return -1
  let n = int(values[0])
  if length < csize_t(n + 2): return -1
  let mValue = values[n + 1]
  if mValue < 1 or mValue > int64(MaxM) or length != csize_t(n + int(mValue) + 2): return -1
  let m = int(mValue)
  var text: array[MaxN, int64]
  var query: array[MaxM, int64]
  var suffix: array[MaxN, int]
  var lcp: array[MaxN, int]
  var leftQ, rightQ: array[MaxN * MaxN, int]
  for i in 0 ..< n:
    text[i] = values[1 + i]
    if text[i] < 0 or text[i] > 127: return -1
    suffix[i] = i
  for i in 0 ..< m:
    query[i] = values[n + 2 + i]
    if query[i] < 0 or query[i] > 127: return -1
  for i in 1 ..< n:
    let key = suffix[i]
    var j = i
    while j > 0 and suffixCmp(text, key, suffix[j - 1], n) < 0:
      suffix[j] = suffix[j - 1]
      dec j
    suffix[j] = key
  for i in 0 ..< (n - 1):
    let a = suffix[i]
    let b = suffix[i + 1]
    var k = 0
    while a + k < n and b + k < n and text[a + k] == text[b + k]: inc k
    lcp[i] = k
  buildIntervals(n, lcp, leftQ, rightQ)
  let first = bound(text, n, query, m, suffix, leftQ, rightQ, false)
  let last = bound(text, n, query, m, suffix, leftQ, rightQ, true)
  let count = last - first
  let byteCount = 8 * (count + 1)
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  var staged: array[MaxOutput, uint8]
  for b in 0 ..< 8: staged[b] = uint8((uint64(count) shr (8 * b)) and 255)
  for i in 0 ..< count:
    let word = uint64(suffix[first + i])
    for b in 0 ..< 8: staged[8 * (i + 1) + b] = uint8((word shr (8 * b)) and 255)
  for i in 0 ..< byteCount: output[i] = staged[i]
  int64(byteCount)
