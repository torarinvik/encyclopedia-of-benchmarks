type
  InputPtr = ptr UncheckedArray[int64]

const MaxM = 8
const MaxQ = 8
const MaxN = 16
const MaxLength = 147
const NoSuccessor = 34'i64

proc fractional_cascading_subset_chain*(input: InputPtr, length: csize_t): int64
  {.cdecl, exportc: "fractional_cascading_subset_chain".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxLength): return -1
  if input[0] < 2 or input[0] > MaxM or input[1] < 1 or input[1] > MaxQ: return -1
  let m = int(input[0])
  let q = int(input[1])
  let total = int(length)
  var catalogs: array[MaxM, array[MaxN, int64]]
  var sizes: array[MaxM, int]
  var cursor = 2
  for i in 0 ..< m:
    if cursor >= total or input[cursor] < 1 or input[cursor] > MaxN: return -1
    let n = int(input[cursor])
    inc cursor
    if cursor + n > total: return -1
    sizes[i] = n
    for j in 0 ..< n:
      let key = input[cursor]
      inc cursor
      if key < -16 or key > 16 or (j > 0 and catalogs[i][j - 1] >= key): return -1
      catalogs[i][j] = key
    if i > 0:
      var parentPos = 0
      var childPos = 0
      while parentPos < sizes[i - 1] and childPos < n:
        if catalogs[i - 1][parentPos] < catalogs[i][childPos]:
          inc parentPos
        elif catalogs[i - 1][parentPos] == catalogs[i][childPos]:
          inc parentPos
          inc childPos
        else:
          return -1
      if childPos != n: return -1
  if cursor + q != total: return -1
  for i in 0 ..< q:
    if input[cursor + i] < -17 or input[cursor + i] > 17: return -1

  var bridge: array[MaxM - 1, array[MaxN + 1, int]]
  for i in 0 ..< m - 1:
    var childPos = 0
    for slot in 0 ..< sizes[i]:
      while childPos < sizes[i + 1] and catalogs[i + 1][childPos] < catalogs[i][slot]:
        inc childPos
      bridge[i][slot] = childPos
    bridge[i][sizes[i]] = sizes[i + 1]

  var checksum = 0'i64
  for qi in 0 ..< q:
    let key = input[cursor + qi]
    var low = 0
    var high = sizes[0]
    while low < high:
      let middle = (low + high) div 2
      if catalogs[0][middle] < key: low = middle + 1 else: high = middle
    var slot = low
    for ci in 0 ..< m:
      let code = if slot < sizes[ci]: catalogs[ci][slot] + 17 else: NoSuccessor
      checksum += int64(qi + 1) * int64(ci + 1) * code
      if ci + 1 < m: slot = bridge[ci][slot]
  checksum
