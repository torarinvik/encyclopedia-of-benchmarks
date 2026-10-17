const MaxN = 256
const MaxMerges = 512
const MaxParseableInputLength = 1028

proc merge_find_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "merge_find_set".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxParseableInputLength): return -1
  let nWord = input[0]
  let mergeCountWord = input[1]
  if nWord < 1'i64 or nWord > int64(MaxN) or
      mergeCountWord < 0'i64 or mergeCountWord > int64(MaxMerges): return -1
  let n = int(nWord)
  let mergeCount = int(mergeCountWord)
  if int(length) != 2 * mergeCount + 3: return -1

  var parents: array[MaxN, int64]
  var ranks: array[MaxN, int64]
  for element in 0 ..< n: parents[element] = int64(element)
  for operation in 0 ..< mergeCount:
    let position = 2 + 2 * operation
    let first = input[position]
    let second = input[position + 1]
    if first < 0 or second < 0 or first >= nWord or second >= nWord: return -1
    var firstRoot = int(first)
    var secondRoot = int(second)
    while parents[firstRoot] != int64(firstRoot): firstRoot = int(parents[firstRoot])
    while parents[secondRoot] != int64(secondRoot): secondRoot = int(parents[secondRoot])
    if firstRoot == secondRoot: continue
    if ranks[firstRoot] < ranks[secondRoot]:
      parents[firstRoot] = int64(secondRoot)
    elif ranks[firstRoot] > ranks[secondRoot]:
      parents[secondRoot] = int64(firstRoot)
    else:
      parents[firstRoot] = int64(secondRoot)
      inc ranks[secondRoot]

  let query = input[int(length) - 1]
  if query < 0 or query >= nWord: return -1
  var root = int(query)
  while parents[root] != int64(root): root = int(parents[root])
  int64(root)
