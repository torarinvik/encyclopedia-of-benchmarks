const
  MaxN = 64
  MaxK = 4
  MaxInput = 67
  MaxOutput = 320
  Levels = 7

proc pairLess(a, b, width: int, rank: openArray[uint8], n: int): bool =
  if rank[a] != rank[b]: return rank[a] < rank[b]
  let ra = if a + width < n: int(rank[a + width]) else: -1
  let rb = if b + width < n: int(rank[b + width]) else: -1
  ra < rb

proc lce(a, b, n: int, inverse: openArray[int], sparse: openArray[uint8], logs: openArray[uint8]): int =
  if a >= n or b >= n: return 0
  if a == b: return n - a
  var left = inverse[a]
  var right = inverse[b]
  if left > right: swap(left, right)
  inc left
  let count = right - left + 1
  let level = int(logs[count])
  let span = 1 shl level
  int(min(sparse[level * MaxN + left], sparse[level * MaxN + right - span + 1]))

proc k_mismatch_longest_extension_table*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "k_mismatch_longest_extension_table".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let budgetValue = input[1]
  if nValue < 1 or nValue > MaxN or budgetValue < 0 or budgetValue > MaxK: return -1
  let n = int(nValue)
  let budget = int(budgetValue)
  if int(length) != n + 2: return -1

  var text: array[MaxN, uint8]
  var suffixes: array[MaxN, int]
  var rank: array[MaxN, uint8]
  var inverse: array[MaxN, int]
  var lcp: array[MaxN, uint8]
  var sparse: array[Levels * MaxN, uint8]
  var logs: array[MaxN + 1, uint8]
  var staged: array[MaxOutput, uint8]
  for i in 0..<n:
    if input[i + 2] < 0 or input[i + 2] > 25: return -1
    text[i] = uint8(input[i + 2])
    suffixes[i] = i
    rank[i] = text[i]

  var width = 1
  while width < n:
    for i in 1..<n:
      let key = suffixes[i]
      var j = i
      while j > 0 and pairLess(key, suffixes[j - 1], width, rank, n):
        suffixes[j] = suffixes[j - 1]
        dec j
      suffixes[j] = key
    var nextRank: array[MaxN, uint8]
    var classes = 0
    nextRank[suffixes[0]] = 0
    for i in 1..<n:
      let a = suffixes[i - 1]
      let b = suffixes[i]
      let a2 = if a + width < n: int(rank[a + width]) else: -1
      let b2 = if b + width < n: int(rank[b + width]) else: -1
      if rank[a] != rank[b] or a2 != b2: inc classes
      nextRank[b] = uint8(classes)
    rank = nextRank
    if classes == n - 1 or width > n div 2: break
    width *= 2

  for i in 0..<n: inverse[suffixes[i]] = i
  var matched = 0
  for start in 0..<n:
    let order = inverse[start]
    if order == 0:
      matched = 0
      continue
    let other = suffixes[order - 1]
    while start + matched < n and other + matched < n and text[start + matched] == text[other + matched]: inc matched
    lcp[order] = uint8(matched)
    if matched > 0: dec matched
  for i in 0..<n: sparse[i] = lcp[i]
  for level in 1..<Levels:
    let span = 1 shl level
    let half = span div 2
    var i = 0
    while i + span <= n:
      sparse[level * MaxN + i] = min(sparse[(level - 1) * MaxN + i], sparse[(level - 1) * MaxN + i + half])
      inc i
  for count in 2..n: logs[count] = logs[count div 2] + 1

  var written = 0
  for p in 0..<n:
    let limit = n - p
    var extension = min(limit, lce(0, p, n, inverse, sparse, logs))
    staged[written] = uint8(extension)
    inc written
    var k = 1
    while k <= budget:
      if extension < limit:
        extension = min(limit, extension + 1 + lce(extension + 1, p + extension + 1, n, inverse, sparse, logs))
      staged[written] = uint8(extension)
      inc written
      inc k
  if written > MaxOutput: return -1
  if output.isNil or capacity < csize_t(written): return -2
  for i in 0..<written: output[i] = staged[i]
  int64(written)
