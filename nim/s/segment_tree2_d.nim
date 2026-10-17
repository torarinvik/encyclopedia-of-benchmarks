const MaxRows = 16
const MaxColumns = 16
const MaxOperations = 256
const MaxTreeSide = 64
const MaxValidInputLength = 1283
const MaxParseableInputLength = 1284
const ChecksumOffset = 256001'i64

type SegmentTree2DStorage = array[MaxTreeSide, array[MaxTreeSide, int64]]

proc setColumn(tree: var SegmentTree2DStorage, rowNode, columnBase, column: int, value: int64) =
  var node = columnBase + column
  tree[rowNode][node] = value
  node = node shr 1
  while node > 0:
    tree[rowNode][node] = tree[rowNode][node shl 1] + tree[rowNode][(node shl 1) or 1]
    node = node shr 1

proc queryColumns(tree: SegmentTree2DStorage, rowNode, columnBase, left, right: int): int64 =
  var first = left + columnBase
  var last = right + columnBase
  while first < last:
    if (first and 1) != 0:
      result += tree[rowNode][first]
      inc first
    if (last and 1) != 0:
      dec last
      result += tree[rowNode][last]
    first = first shr 1
    last = last shr 1

proc assignPoint(tree: var SegmentTree2DStorage, rowBase, columnBase, row, column: int, value: int64) =
  let rowLeaf = rowBase + row
  setColumn(tree, rowLeaf, columnBase, column, value)
  var rowNode = rowLeaf shr 1
  while rowNode > 0:
    let leftValue = tree[rowNode shl 1][columnBase + column]
    let rightValue = tree[(rowNode shl 1) or 1][columnBase + column]
    setColumn(tree, rowNode, columnBase, column, leftValue + rightValue)
    rowNode = rowNode shr 1

proc queryRectangle(tree: SegmentTree2DStorage, rowBase, columnBase, top, bottom, left, right: int): int64 =
  var first = top + rowBase
  var last = bottom + rowBase
  while first < last:
    if (first and 1) != 0:
      result += queryColumns(tree, first, columnBase, left, right)
      inc first
    if (last and 1) != 0:
      dec last
      result += queryColumns(tree, last, columnBase, left, right)
    first = first shr 1
    last = last shr 1

proc segment_tree2_d_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_tree2_d_benchmark".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 1 or input[0] > MaxRows or input[1] < 1 or input[1] > MaxColumns: return -1
  if input[2] < 0 or input[2] > MaxOperations: return -1
  let rows = int(input[0])
  let columns = int(input[1])
  let operationCount = int(input[2])
  if length != csize_t(3 + 5 * operationCount) or length > csize_t(MaxValidInputLength): return -1

  var rowBase = 1
  while rowBase < rows: rowBase = rowBase shl 1
  var columnBase = 1
  while columnBase < columns: columnBase = columnBase shl 1
  var tree: SegmentTree2DStorage
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let offset = 3 + 5 * operation
    let opcode = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    let third = input[offset + 3]
    let fourth = input[offset + 4]
    if opcode == 0:
      if first < 0 or first >= int64(rows) or second < 0 or second >= int64(columns) or third < -1000 or third > 1000 or fourth != 0: return -1
      assignPoint(tree, rowBase, columnBase, int(first), int(second), third)
    elif opcode == 1:
      if first < 0 or first > second or second > int64(rows) or third < 0 or third > fourth or fourth > int64(columns): return -1
      let value = queryRectangle(tree, rowBase, columnBase, int(first), int(second), int(third), int(fourth))
      checksum += int64(operation + 1) * (value + ChecksumOffset)
    else:
      return -1
  checksum
