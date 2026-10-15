## Merge two heap-indexed trees and encode the result as little-endian i32 slots.
const MaxTreeSlots = 255
const MaxInputLength = 512
const NullSlot = -1_000_001'i64

proc validTree(input: ptr UncheckedArray[int64], start, count: int): bool =
  for index in 0 ..< count:
    let value = input[start + index]
    if value != NullSlot and (value < -100_000 or value > 100_000): return false
    if index > 0 and input[start + (index - 1) div 2] == NullSlot and value != NullSlot: return false
  true

proc merge_two_binary_trees*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "merge_two_binary_trees".} =
  if length < 2 or length > csize_t(MaxInputLength) or input == nil: return -1
  if input[0] < 0 or input[0] > MaxTreeSlots: return -1
  let firstCount = int(input[0])
  let secondCountPosition = firstCount + 1
  if secondCountPosition >= int(length): return -1
  if input[secondCountPosition] < 0 or input[secondCountPosition] > MaxTreeSlots: return -1
  let secondCount = int(input[secondCountPosition])
  let firstStart = 1
  let secondStart = secondCountPosition + 1
  if int(length) != secondStart + secondCount: return -1
  if not validTree(input, firstStart, firstCount) or not validTree(input, secondStart, secondCount): return -1

  let maximumSlots = max(firstCount, secondCount)
  var merged: array[MaxTreeSlots, int32]
  var nodeCount = 0
  for index in 0 ..< maximumSlots:
    let first = if index < firstCount: input[firstStart + index] else: NullSlot
    let second = if index < secondCount: input[secondStart + index] else: NullSlot
    if first == NullSlot and second == NullSlot:
      merged[index] = int32(NullSlot)
    else:
      let firstValue = if first == NullSlot: 0'i64 else: first
      let secondValue = if second == NullSlot: 0'i64 else: second
      merged[index] = int32(firstValue + secondValue)
      inc nodeCount
  var outputSlots = maximumSlots
  while outputSlots > 0 and merged[outputSlots - 1] == int32(NullSlot): dec outputSlots
  let outputBytes = outputSlots * 4
  if int(outputCapacity) < outputBytes or (outputBytes != 0 and output == nil): return -2
  for index in 0 ..< outputSlots:
    let bits = cast[uint32](merged[index])
    for byte in 0 ..< 4: output[index * 4 + byte] = uint8((bits shr (byte * 8)) and 255'u32)
  int64(nodeCount)
