const MaxN = 32
const MaxQ = 128
const MaxInput = 419
const TBytes = 43
const LBytes = 128
const TMaxBits = 340
const NodeCap = 256

proc bitGet(bits: ptr UncheckedArray[uint8], index: int): uint8 =
  (bits[index shr 3] shr (index and 7)) and 1'u8

proc bitSet(bits: ptr UncheckedArray[uint8], index: int) =
  bits[index shr 3] = bits[index shr 3] or (1'u8 shl (index and 7))

proc blockNonempty(rows: ptr UncheckedArray[int64], rowOffset, n,
    rowStart, colStart, side: int): bool =
  let mask = ((1'u64 shl side) - 1) shl colStart
  for row in rowStart ..< rowStart + side:
    if row < n and (cast[uint64](rows[rowOffset + row]) and mask) != 0: return true
  false

proc buildTree(rows: ptr UncheckedArray[int64], rowOffset, n: int,
    tBits: ptr UncheckedArray[uint8], lBits: ptr UncheckedArray[uint8],
    rankPrefix: ptr UncheckedArray[uint16], currentRows, currentCols,
    nextRows, nextCols: ptr UncheckedArray[uint8]): tuple[tLen, lLen, height: int] =
  var side = 2
  var height = 1
  while side < n:
    side = side shl 1
    inc height
  var currentCount = 1
  var currentSide = side
  var tLen = 0
  var lLen = 0
  currentRows[0] = 0
  currentCols[0] = 0
  for level in 1 .. height:
    let childSide = currentSide div 2
    var nextCount = 0
    for parent in 0 ..< currentCount:
      let parentRow = int(currentRows[parent])
      let parentCol = int(currentCols[parent])
      for quadrant in 0 ..< 4:
        let childRow = parentRow + (quadrant div 2) * childSide
        let childCol = parentCol + (quadrant mod 2) * childSide
        let occupied = blockNonempty(rows, rowOffset, n, childRow, childCol, childSide)
        if level < height:
          if occupied:
            bitSet(tBits, tLen)
            nextRows[nextCount] = uint8(childRow)
            nextCols[nextCount] = uint8(childCol)
            inc nextCount
          inc tLen
        else:
          if occupied: bitSet(lBits, lLen)
          inc lLen
    if level < height:
      for i in 0 ..< nextCount:
        currentRows[i] = nextRows[i]
        currentCols[i] = nextCols[i]
      currentCount = nextCount
      currentSide = childSide
  rankPrefix[0] = 0
  for i in 0 ..< tLen:
    rankPrefix[i + 1] = rankPrefix[i] + uint16(bitGet(tBits, i))
  (tLen, lLen, height)

proc edgeQuery(tBits: ptr UncheckedArray[uint8], lBits: ptr UncheckedArray[uint8],
    tLen: int, rankPrefix: ptr UncheckedArray[uint16], height, u, v: int): bool =
  var parent = -1
  var rowStart = 0
  var colStart = 0
  var side = 1 shl height
  for _ in 0 ..< height:
    let childSide = side div 2
    let rowBit = ord(u >= rowStart + childSide)
    let colBit = ord(v >= colStart + childSide)
    let quadrant = 2 * rowBit + colBit
    let childBase = if parent < 0: 0 else: 4 * int(rankPrefix[parent + 1])
    let child = childBase + quadrant
    if rowBit != 0: rowStart += childSide
    if colBit != 0: colStart += childSide
    if child < tLen:
      if bitGet(tBits, child) == 0: return false
      parent = child
    else:
      return bitGet(lBits, child - tLen) != 0
    side = childSide
  false

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  var bits = value
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc k2_tree_compact_graph*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "k2_tree_compact_graph".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN) or length < csize_t(nValue + 2): return -1
  let n = int(nValue)
  let rowLimit = (1'u64 shl n) - 1
  for row in 0 ..< n:
    if input[1 + row] < 0 or cast[uint64](input[1 + row]) > rowLimit: return -1
  let qIndex = n + 1
  let qValue = input[qIndex]
  if qValue < 0 or qValue > int64(MaxQ): return -1
  let q = int(qValue)
  if int64(length) != int64(n + 2 + 3 * q): return -1
  let queryStart = n + 2
  for j in 0 ..< q:
    let op = input[queryStart + 3 * j]
    let u = input[queryStart + 3 * j + 1]
    let v = input[queryStart + 3 * j + 2]
    if u < 0 or u >= nValue: return -1
    if op == 0:
      if v < 0 or v >= nValue: return -1
    elif op == 1:
      if v != 0: return -1
    else:
      return -1
  let outputBytes = 8 * (q + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var tBits: array[TBytes, uint8]
  var lBits: array[LBytes, uint8]
  var rankPrefix: array[TMaxBits + 1, uint16]
  var currentRows, currentCols, nextRows, nextCols: array[NodeCap, uint8]
  let built = buildTree(input, 1, n, cast[ptr UncheckedArray[uint8]](addr tBits[0]),
    cast[ptr UncheckedArray[uint8]](addr lBits[0]),
    cast[ptr UncheckedArray[uint16]](addr rankPrefix[0]),
    cast[ptr UncheckedArray[uint8]](addr currentRows[0]),
    cast[ptr UncheckedArray[uint8]](addr currentCols[0]),
    cast[ptr UncheckedArray[uint8]](addr nextRows[0]),
    cast[ptr UncheckedArray[uint8]](addr nextCols[0]))
  putI64Le(output, 0, uint64(q))
  for j in 0 ..< q:
    let op = input[queryStart + 3 * j]
    let u = int(input[queryStart + 3 * j + 1])
    let v = int(input[queryStart + 3 * j + 2])
    var result = 0'u64
    if op == 0:
      result = uint64(ord(edgeQuery(cast[ptr UncheckedArray[uint8]](addr tBits[0]),
        cast[ptr UncheckedArray[uint8]](addr lBits[0]), built.tLen,
        cast[ptr UncheckedArray[uint16]](addr rankPrefix[0]), built.height, u, v)))
    else:
      for successor in 0 ..< n:
        if edgeQuery(cast[ptr UncheckedArray[uint8]](addr tBits[0]),
            cast[ptr UncheckedArray[uint8]](addr lBits[0]), built.tLen,
            cast[ptr UncheckedArray[uint16]](addr rankPrefix[0]), built.height, u, successor):
          result = result or (1'u64 shl successor)
    putI64Le(output, 8 * (j + 1), result)
  int64(outputBytes)
