const MaxQ = 48
const MaxCons = 32
const MaxRoots = 49
const MaxBlocks = 6
const MaxSlots = 63
const MaxParseable = 146

type Block = object
  previousBlock: int32
  previousOffset: int32
  capacity: int32
  lastUsed: int32
  base: int32

proc listLength(blocks: var array[MaxBlocks, Block], rootBlock: var array[MaxRoots, int32],
                rootOffset: var array[MaxRoots, int32], root: int): int64 =
  var blockId = rootBlock[root]
  var offset = rootOffset[root]
  var total = 0'i64
  while blockId >= 0:
    if int(blockId) >= MaxBlocks or offset < 0 or offset > blocks[int(blockId)].lastUsed:
      return -1
    total += int64(offset) + 1
    let previous = blocks[int(blockId)].previousBlock
    offset = blocks[int(blockId)].previousOffset
    blockId = previous
  total

proc listNth(blocks: var array[MaxBlocks, Block], data: var array[MaxSlots, int64],
             rootBlock: var array[MaxRoots, int32], rootOffset: var array[MaxRoots, int32],
             root, index: int): int64 =
  var blockId = rootBlock[root]
  var offset = rootOffset[root]
  var remaining = index
  while blockId >= 0:
    if int(blockId) >= MaxBlocks or offset < 0 or offset > blocks[int(blockId)].lastUsed:
      return -1_000_001
    if remaining <= int(offset):
      let position = int(blocks[int(blockId)].base + offset) - remaining
      return data[position]
    remaining -= int(offset) + 1
    let previous = blocks[int(blockId)].previousBlock
    offset = blocks[int(blockId)].previousOffset
    blockId = previous
  -1_000_001'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byteIndex in 0 ..< 8:
    output[offset + byteIndex] = uint8((bits shr (8 * byteIndex)) and 255'u64)

proc vlist_persistent_sequence*(input: ptr UncheckedArray[int64], length: csize_t,
                               output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "vlist_persistent_sequence".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseable): return -1
  let qWord = input[0]
  if qWord < 1 or qWord > MaxQ or length != csize_t(1 + 3 * int(qWord)): return -1
  let q = int(qWord)

  var blocks: array[MaxBlocks, Block]
  var data: array[MaxSlots, int64]
  var rootBlock: array[MaxRoots, int32]
  var rootOffset: array[MaxRoots, int32]
  var results: array[MaxQ, int64]
  for i in 0 ..< MaxRoots:
    rootBlock[i] = -1
    rootOffset[i] = -1
  var blockCount = 0
  var rootCount = 1
  var slotCount = 0
  var consCount = 0
  var queryPhase = false
  var at = 1
  for op in 0 ..< q:
    let tag = input[at]
    let rootWord = input[at + 1]
    let arg = input[at + 2]
    at += 3
    if tag < 0 or tag > 3 or rootWord < 0 or rootWord >= int64(rootCount): return -1
    let root = int(rootWord)
    if tag == 0:
      if queryPhase or root != rootCount - 1 or consCount >= MaxCons or arg < -1_000_000 or arg > 1_000_000: return -1
      var blockId = int(rootBlock[root])
      var offset = int(rootOffset[root])
      if blockId < 0:
        if consCount != 0 or blockCount != 0 or slotCount >= MaxSlots: return -1
        blocks[blockCount] = Block(previousBlock: -1, previousOffset: -1, capacity: 1,
                                  lastUsed: 0, base: int32(slotCount))
        data[slotCount] = arg
        blockId = blockCount
        offset = 0
        blockCount += 1
        slotCount += 1
      else:
        if blockId >= blockCount or offset != int(blocks[blockId].lastUsed): return -1
        if offset + 1 < int(blocks[blockId].capacity):
          offset += 1
          data[int(blocks[blockId].base) + offset] = arg
          blocks[blockId].lastUsed = int32(offset)
        else:
          let nextCapacity = int(blocks[blockId].capacity) * 2
          if blockCount >= MaxBlocks or slotCount + nextCapacity > MaxSlots: return -1
          blocks[blockCount] = Block(previousBlock: int32(blockId), previousOffset: int32(offset),
                                    capacity: int32(nextCapacity), lastUsed: 0,
                                    base: int32(slotCount))
          data[slotCount] = arg
          blockId = blockCount
          offset = 0
          blockCount += 1
          slotCount += nextCapacity
      if rootCount >= MaxRoots: return -1
      rootBlock[rootCount] = int32(blockId)
      rootOffset[rootCount] = int32(offset)
      results[op] = int64(rootCount)
      rootCount += 1
      consCount += 1
    else:
      queryPhase = true
      if tag == 1:
        if arg != -1 or listLength(blocks, rootBlock, rootOffset, root) <= 0: return -1
        var blockId = int(rootBlock[root])
        var offset = int(rootOffset[root])
        if offset > 0:
          offset -= 1
        else:
          offset = int(blocks[blockId].previousOffset)
          blockId = int(blocks[blockId].previousBlock)
        if rootCount >= MaxRoots: return -1
        rootBlock[rootCount] = int32(blockId)
        rootOffset[rootCount] = int32(offset)
        results[op] = int64(rootCount)
        rootCount += 1
      elif tag == 2:
        let n = listLength(blocks, rootBlock, rootOffset, root)
        if n < 0 or arg < 0 or arg >= n: return -1
        let value = listNth(blocks, data, rootBlock, rootOffset, root, int(arg))
        if value == -1_000_001: return -1
        results[op] = value
      else:
        if arg != -1: return -1
        let n = listLength(blocks, rootBlock, rootOffset, root)
        if n < 0: return -1
        results[op] = n
  let bytes = q * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< q: storeI64Le(output, i * 8, results[i])
  int64(bytes)
