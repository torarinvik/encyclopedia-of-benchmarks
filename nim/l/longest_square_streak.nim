const MaxInputLength = 100000
const MaxValue = 100000
const RequiredWorkspace = csize_t(4 * (MaxValue + 1))

proc readState(workspace: ptr UncheckedArray[uint8], value: int): int64 =
  let position = 4 * value
  let encoded = uint32(workspace[position]) or (uint32(workspace[position + 1]) shl 8) or
      (uint32(workspace[position + 2]) shl 16) or (uint32(workspace[position + 3]) shl 24)
  int64(encoded)

proc writeState(workspace: ptr UncheckedArray[uint8], value: int, state: int64) =
  let encoded = uint32(state)
  let position = 4 * value
  workspace[position] = uint8(encoded and 255)
  workspace[position + 1] = uint8((encoded shr 8) and 255)
  workspace[position + 2] = uint8((encoded shr 16) and 255)
  workspace[position + 3] = uint8((encoded shr 24) and 255)

proc streakFrom(workspace: ptr UncheckedArray[uint8], value: int): int64 =
  let state = readState(workspace, value)
  if state > 1: return state - 1
  var chainLength = 1'i64
  let square = int64(value) * int64(value)
  if square <= MaxValue and readState(workspace, int(square)) != 0:
    chainLength += streakFrom(workspace, int(square))
  writeState(workspace, value, chainLength + 1)
  chainLength

proc longest_square_streak*(values: ptr UncheckedArray[int64], length: csize_t,
    workspace: ptr UncheckedArray[uint8], workspaceCapacity: csize_t): int64
    {.cdecl, exportc: "longest_square_streak".} =
  if values.isNil or length < 3 or length > MaxInputLength + 1 or
      values[0] < 2 or values[0] > MaxInputLength: return -1
  let count = int(values[0])
  if int(length) != count + 1: return -1
  for index in 0 ..< count:
    if values[index + 1] < 2 or values[index + 1] > MaxValue: return -1
  if workspace.isNil or workspaceCapacity < RequiredWorkspace: return -2
  for byteIndex in 0 ..< int(RequiredWorkspace): workspace[byteIndex] = 0
  for index in 0 ..< count: writeState(workspace, int(values[index + 1]), 1)
  var longest = 1'i64
  for index in 0 ..< count:
    let found = streakFrom(workspace, int(values[index + 1]))
    if found > longest: longest = found
  if longest >= 2: longest else: -1
