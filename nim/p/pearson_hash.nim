const TableSize = 256
const MaxText = 64
const MaxWords = 1 + TableSize + MaxText

proc pearson_hash*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pearson_hash".} =
  if input.isNil or length < 1 + TableSize or length > MaxWords + 1: return -1
  let declared = input[0]
  if declared < 0 or declared > MaxText or
      length != csize_t(1 + TableSize) + csize_t(declared): return -1

  var table: array[TableSize, uint8]
  var used: array[TableSize, bool]
  for slot in 0 ..< TableSize:
    let value = input[1 + slot]
    if value < 0 or value > 255: return -1
    let byte = int(value)
    if used[byte]: return -1
    used[byte] = true
    table[slot] = uint8(byte)

  let textStart = 1 + TableSize
  for offset in 0 ..< int(declared):
    let value = input[textStart + offset]
    if value < 0 or value > 255: return -1
  var state = 0'u8
  for offset in 0 ..< int(declared):
    let byte = uint8(input[textStart + offset])
    state = table[int(state xor byte)]
  int64(state)
