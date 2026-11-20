const LcmPpcMaxItems = 8
const LcmPpcMaxRows = 16
const LcmPpcMaxWords = 513

proc lcmPpcSupport(rows: ptr UncheckedArray[int64], rowCount: int, mask: int64): int =
  var count = 0
  for row in 0 ..< rowCount:
    if (rows[row] and mask) == mask: inc count
  count

proc lcmPpcClosure(rows: ptr UncheckedArray[int64], rowCount, itemCount: int,
    mask: int64): int64 =
  var common = (1'i64 shl itemCount) - 1
  for row in 0 ..< rowCount:
    if (rows[row] and mask) == mask: common = common and rows[row]
  common

proc lcmPpcCore(rows: ptr UncheckedArray[int64], rowCount, itemCount: int,
    mask: int64, patternSupport: int): int =
  for item in 0 ..< itemCount:
    let prefixMask = (1'i64 shl (item + 1)) - 1
    if lcmPpcSupport(rows, rowCount, mask and prefixMask) == patternSupport:
      return item
  itemCount - 1

proc lcmPpcPutI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255)

proc lcm_ppc_closed_itemset_enumeration*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lcm_ppc_closed_itemset_enumeration".} =
  if input.isNil or length < 4 or length > csize_t(3 + LcmPpcMaxRows): return -1
  let itemValue = input[0]
  let rowValue = input[1]
  let minimum = input[2]
  if itemValue < 1 or itemValue > LcmPpcMaxItems or rowValue < 1 or
      rowValue > LcmPpcMaxRows or minimum < 1 or minimum > rowValue or
      length != csize_t(3 + rowValue): return -1
  let itemCount = int(itemValue)
  let rowCount = int(rowValue)
  let limit = 1'i64 shl itemCount
  var rows: array[LcmPpcMaxRows, int64]
  for row in 0 ..< rowCount:
    let mask = input[3 + row]
    if mask < 0 or mask >= limit: return -1
    rows[row] = mask
  let rowPtr = cast[ptr UncheckedArray[int64]](addr rows[0])

  var words: array[LcmPpcMaxWords, int64]
  var stackMask: array[LcmPpcMaxItems + 1, int64]
  var stackSupport: array[LcmPpcMaxItems + 1, int]
  var stackCore: array[LcmPpcMaxItems + 1, int]
  var nextItem: array[LcmPpcMaxItems + 1, int]
  var entered: array[LcmPpcMaxItems + 1, bool]
  stackMask[0] = lcmPpcClosure(rowPtr, rowCount, itemCount, 0)
  stackSupport[0] = rowCount
  stackCore[0] = -1
  var depth = 0
  var recordCount = 0
  var active = true
  while active:
    if not entered[depth]:
      words[1 + 2 * recordCount] = stackMask[depth]
      words[2 + 2 * recordCount] = int64(stackSupport[depth])
      inc recordCount
      entered[depth] = true
      nextItem[depth] = stackCore[depth] + 1
    if nextItem[depth] >= itemCount:
      entered[depth] = false
      if depth == 0: active = false
      else: dec depth
      continue

    let item = nextItem[depth]
    inc nextItem[depth]
    let bit = 1'i64 shl item
    let parentMask = stackMask[depth]
    if (parentMask and bit) != 0: continue
    let extended = parentMask or bit
    let childSupport = lcmPpcSupport(rowPtr, rowCount, extended)
    if childSupport < int(minimum): continue
    let child = lcmPpcClosure(rowPtr, rowCount, itemCount, extended)
    let lowerPrefix = bit - 1
    if (parentMask and lowerPrefix) != (child and lowerPrefix): continue
    inc depth
    stackMask[depth] = child
    stackSupport[depth] = childSupport
    stackCore[depth] = lcmPpcCore(rowPtr, rowCount, itemCount, child, childSupport)
    entered[depth] = false

  words[0] = int64(recordCount)
  let outputBytes = 8 * (1 + 2 * recordCount)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for word in 0 ..< 1 + 2 * recordCount:
    lcmPpcPutI64Le(output, word, words[word])
  int64(outputBytes)
