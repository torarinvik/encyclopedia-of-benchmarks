type
  XftLevels = array[17 * 24, int64]
  XftCounts = array[17, int]
  XftInput = ptr UncheckedArray[int64]

const
  MaxKeys = 24
  MaxQueries = 24
  UniverseBits = 16
  LevelCount = 17
  MaxParseable = 51

proc prefixOf(key: int64, depth: int): int64 =
  if depth == 0: 0 else: key shr (UniverseBits - depth)

proc findPrefix(prefixes: XftLevels, counts: XftCounts, depth: int, wanted: int64): int =
  var low = 0
  var high = counts[depth]
  let row = depth * MaxKeys
  while low < high:
    let middle = low + (high - low) div 2
    if prefixes[row + middle] < wanted: low = middle + 1 else: high = middle
  if low < counts[depth] and prefixes[row + low] == wanted: low else: -1

proc predecessor(prefixes: XftLevels, maxima: XftLevels, counts: XftCounts, query: int64): int64 =
  var low = 0
  var high = LevelCount
  while high - low > 1:
    let middle = low + (high - low) div 2
    if findPrefix(prefixes, counts, middle, prefixOf(query, middle)) >= 0: low = middle
    else: high = middle
  if low == UniverseBits: return query
  var depth = low + 1
  while depth > 0:
    let queryPrefix = query shr (UniverseBits - depth)
    if (queryPrefix and 1) != 0:
      let position = findPrefix(prefixes, counts, depth, queryPrefix - 1)
      if position >= 0: return maxima[depth * MaxKeys + position]
    dec depth
  -1

proc x_fast_trie_static_predecessor*(input: XftInput, length: csize_t): int64
    {.cdecl, exportc: "x_fast_trie_static_predecessor".} =
  if input == nil or length < 2 or length > csize_t(MaxParseable): return -1
  if input[0] < 0 or input[0] > MaxKeys.int64 or input[1] < 0 or input[1] > MaxQueries.int64: return -1
  let n = int(input[0])
  let q = int(input[1])
  if int(length) != 2 + n + q: return -1
  var keys: array[MaxKeys, int64]
  var queries: array[MaxQueries, int64]
  for i in 0 ..< n:
    keys[i] = input[2 + i]
    if keys[i] < 0 or keys[i] > 65535: return -1
  for i in 1 ..< n:
    let key = keys[i]
    var at = i
    while at > 0 and key < keys[at - 1]:
      keys[at] = keys[at - 1]
      dec at
    keys[at] = key
  for i in 1 ..< n:
    if keys[i] == keys[i - 1]: return -1
  for i in 0 ..< q:
    queries[i] = input[2 + n + i]
    if queries[i] < 0 or queries[i] > 65535: return -1
  if n == 0 or q == 0: return 0

  var prefixes: XftLevels
  var maxima: XftLevels
  var counts: XftCounts
  for depth in 0 ..< LevelCount:
    let row = depth * MaxKeys
    for i in 0 ..< n:
      let value = prefixOf(keys[i], depth)
      if counts[depth] == 0 or prefixes[row + counts[depth] - 1] != value:
        prefixes[row + counts[depth]] = value
        maxima[row + counts[depth]] = keys[i]
        inc counts[depth]
      else:
        maxima[row + counts[depth] - 1] = keys[i]
  var checksum = 0'i64
  for i in 0 ..< q:
    checksum += int64(i + 1) * (predecessor(prefixes, maxima, counts, queries[i]) + 1)
  checksum
