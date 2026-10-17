const MaxItems = 128
const MaxParseableInputLength = MaxItems + 2
const FnvOffsetBasis = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64
const Mask63 = 0x7fffffffffffffff'u64

type PairingNode = object
  key: int32
  firstChild: int
  nextSibling: int

proc meld(firstRoot, secondRoot: int, nodes: var array[MaxItems, PairingNode]): int =
  if firstRoot < 0: return secondRoot
  if secondRoot < 0: return firstRoot
  var first = firstRoot
  var second = secondRoot
  if nodes[second].key < nodes[first].key:
    swap(first, second)
  nodes[second].nextSibling = nodes[first].firstChild
  nodes[first].firstChild = second
  nodes[first].nextSibling = -1
  first

proc hashKey(hashValue: uint64, key: int32): uint64 =
  var hash = hashValue
  let bits = cast[uint32](key)
  for shift in countup(0, 24, 8):
    hash = (hash xor uint64((bits shr shift) and 255)) *% FnvPrime
  hash

proc pairing_heap*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pairing_heap".} =
  if values == nil or length < 1 or length > csize_t(MaxParseableInputLength):
    return -1
  let rawCount = values[0]
  if rawCount < 2 or rawCount > int64(MaxItems) or length != csize_t(1 + rawCount):
    return -1
  let count = int(rawCount)

  var nodes: array[MaxItems, PairingNode]
  for index in 0 ..< count:
    let value = values[1 + index]
    if value < int64(low(int32)) or value > int64(high(int32)):
      return -1
    for previous in 0 ..< index:
      if values[1 + previous] == value:
        return -1
    nodes[index].key = int32(value)
    nodes[index].firstChild = -1
    nodes[index].nextSibling = -1

  var root = -1
  for index in 0 ..< count:
    root = meld(root, index, nodes)

  var hash = FnvOffsetBasis
  for extraction in 0 ..< count - 1:
    let removed = root
    hash = hashKey(hash, nodes[removed].key)
    var forest: array[MaxItems, int]
    var paired: array[MaxItems, int]
    var forestCount = 0
    var child = nodes[removed].firstChild
    nodes[removed].firstChild = -1
    while child >= 0:
      let next = nodes[child].nextSibling
      nodes[child].nextSibling = -1
      forest[forestCount] = child
      inc forestCount
      child = next
    var pairedCount = 0
    var index = 0
    while index < forestCount:
      let right = if index + 1 < forestCount: forest[index + 1] else: -1
      paired[pairedCount] = meld(forest[index], right, nodes)
      inc pairedCount
      index += 2
    var rebuilt = -1
    while pairedCount > 0:
      dec pairedCount
      rebuilt = meld(rebuilt, paired[pairedCount], nodes)
    root = rebuilt
  int64(hash and Mask63)
