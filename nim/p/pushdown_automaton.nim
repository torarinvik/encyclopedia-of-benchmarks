const MAX_BYTE_LENGTH = 256'i64
const MAX_INPUT_LENGTH = 257

proc pushdownAutomaton*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pushdown_automaton".} =
  if values == nil or length < 1 or length > csize_t(MAX_INPUT_LENGTH): return -1
  let byteLength = values[0]
  if byteLength < 0 or byteLength > MAX_BYTE_LENGTH: return -1
  let count = int(byteLength)
  if length != csize_t(count + 1): return -1

  for index in 0 ..< count:
    if values[index + 1] < 48 or values[index + 1] > 50: return -1
  if count == 0 or count mod 2 != 0: return 0

  let half = count div 2
  for index in 0 ..< half:
    if values[index + 1] != 49 and values[index + 1] != 50: return 0
  for index in half ..< count:
    if values[index + 1] != 48: return 0
  1
