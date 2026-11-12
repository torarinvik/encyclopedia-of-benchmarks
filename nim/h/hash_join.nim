proc bucketFor(key: int64): int =
  var remainder = key mod 17
  if remainder < 0: remainder += 17
  int(remainder)

proc hash_join*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "hash_join".} =
  if input == nil or length < 2 or length > 19: return -1
  let leftValue = input[0]
  let rightValue = input[1]
  if leftValue < 0 or leftValue > 8 or rightValue < 0 or rightValue > 8: return -1
  let leftCount = int(leftValue)
  let rightCount = int(rightValue)
  if int(length) != 2 + leftCount + rightCount: return -1

  let buildLeft = leftCount < rightCount
  let buildCount = if buildLeft: leftCount else: rightCount
  let probeCount = if buildLeft: rightCount else: leftCount
  let buildOffset = if buildLeft: 2 else: 2 + leftCount
  let probeOffset = if buildLeft: 2 + leftCount else: 2
  var keys: array[17, int64]
  var occupied: array[17, bool]
  var heads: array[17, int]
  var tails: array[17, int]
  var nextRow: array[8, int]
  var staged: array[64, uint8]
  for slot in 0 ..< 17:
    heads[slot] = -1
    tails[slot] = -1
  for row in 0 ..< 8: nextRow[row] = -1

  for row in 0 ..< buildCount:
    let key = input[buildOffset + row]
    var slot = bucketFor(key)
    while occupied[slot] and keys[slot] != key: slot = (slot + 1) mod 17
    if not occupied[slot]:
      occupied[slot] = true
      keys[slot] = key
    if tails[slot] < 0: heads[slot] = row
    else: nextRow[tails[slot]] = row
    tails[slot] = row

  var matchCount = 0
  for probeRow in 0 ..< probeCount:
    let key = input[probeOffset + probeRow]
    var slot = bucketFor(key)
    while occupied[slot] and keys[slot] != key: slot = (slot + 1) mod 17
    if not occupied[slot]: continue
    var buildRow = heads[slot]
    while buildRow >= 0:
      let leftId = if buildLeft: buildRow else: probeRow
      let rightId = if buildLeft: probeRow else: buildRow
      staged[matchCount] = uint8((leftId shl 4) or rightId)
      inc matchCount
      buildRow = nextRow[buildRow]
  if output == nil or outputCapacity < csize_t(matchCount): return -2
  for index in 0 ..< matchCount: output[index] = staged[index]
  int64(matchCount)
