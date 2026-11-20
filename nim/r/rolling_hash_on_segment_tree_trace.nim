const
  MaxN = 20
  MaxQ = 20
  MaxParseableInput = 123
  TreeBase = 32
  TreeSize = 64
  Modulus = 1_000_000_007'i64
  HashBase = 911_382_323'i64

proc rhtConcat(leftHash, rightHash: int64, rightLength: int,
    powers: array[MaxN + 1, int64]): int64 =
  (leftHash * powers[rightLength] + rightHash) mod Modulus

proc rhtPull(treeHash: var array[TreeSize, int64],
    treeLength: var array[TreeSize, int], node: int,
    powers: array[MaxN + 1, int64]) =
  let left = 2 * node
  let right = left + 1
  treeHash[node] = rhtConcat(treeHash[left], treeHash[right],
    treeLength[right], powers)
  treeLength[node] = treeLength[left] + treeLength[right]

proc rhtHashRange(treeHash: array[TreeSize, int64],
    treeLength: array[TreeSize, int], startInput, endInput: int,
    powers: array[MaxN + 1, int64]): int64 =
  var left = startInput
  var right = endInput
  var leftHash = 0'i64
  var rightHash = 0'i64
  var rightLength = 0
  while left < right:
    if left mod 2 == 1:
      leftHash = rhtConcat(leftHash, treeHash[left], treeLength[left], powers)
      inc left
    if right mod 2 == 1:
      dec right
      rightHash = rhtConcat(treeHash[right], rightHash, rightLength, powers)
      rightLength += treeLength[right]
    left = left div 2
    right = right div 2
  rhtConcat(leftHash, rightHash, rightLength, powers)

proc rollingHashOnSegmentTreeTrace*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "rolling_hash_on_segment_tree_trace".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInput): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 0 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + n + 5 * q): return -1

  var powers: array[MaxN + 1, int64]
  powers[0] = 1
  for exponent in 0 ..< MaxN:
    powers[exponent + 1] = (powers[exponent] * HashBase) mod Modulus
  var treeHash: array[TreeSize, int64]
  var treeLength: array[TreeSize, int]
  for index in 0 ..< n:
    let symbol = input[2 + index]
    if symbol < 0 or symbol > 25: return -1
    let leaf = TreeBase + index
    treeHash[leaf] = symbol
    treeLength[leaf] = 1
  var node = TreeBase - 1
  while node > 0:
    rhtPull(treeHash, treeLength, node, powers)
    dec node

  var score = 0'i64
  for operation in 0 ..< q:
    let record = 2 + n + 5 * operation
    let opcode = input[record]
    let aValue = input[record + 1]
    let bValue = input[record + 2]
    let cValue = input[record + 3]
    let dValue = input[record + 4]
    var response = 0'i64

    if opcode == 0:
      if aValue < 0 or aValue >= nValue or bValue < 0 or bValue > 25 or cValue != 0 or dValue != 0:
        return -1
      var leaf = TreeBase + int(aValue)
      treeHash[leaf] = bValue
      treeLength[leaf] = 1
      while leaf > 1:
        leaf = leaf div 2
        rhtPull(treeHash, treeLength, leaf, powers)
    elif opcode == 1:
      if aValue < 0 or aValue > nValue or bValue < 0 or bValue > nValue or
         cValue < 0 or cValue > nValue or dValue < 0 or dValue > nValue or
         aValue > bValue or cValue > dValue:
        return -1
      if bValue - aValue == dValue - cValue:
        let first = rhtHashRange(treeHash, treeLength, TreeBase + int(aValue),
          TreeBase + int(bValue), powers)
        let second = rhtHashRange(treeHash, treeLength, TreeBase + int(cValue),
          TreeBase + int(dValue), powers)
        response = if first == second: 1 else: 0
      else:
        response = 0
    else:
      return -1

    let token = opcode * 2 + response + 1
    score += int64(operation + 1) * token
  score
