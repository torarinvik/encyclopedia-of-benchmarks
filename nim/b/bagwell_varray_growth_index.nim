type
  Location = tuple[pointerSlot, childBase, elementOffset: int]

const LevelStarts = [0, 64, 320]

proc locate(level, index: int): Location =
  let valueStart = LevelStarts[level]
  let side = [8, 16, 32][level]
  let pointerStart = [0, 8, 24][level]
  let relative = index - valueStart
  let child = relative div side
  (pointerStart + child, valueStart + child * side, relative mod side)

proc findLevel(index, currentHeader: int; previousHeader: openArray[int64]): int =
  var level = currentHeader
  while level >= 0 and index < LevelStarts[level]:
    level = int(previousHeader[level])
  level

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc bagwell_varray_growth_index*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bagwell_varray_growth_index".} =
  if input.isNil or length < 2 or length > 580: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 0 or nValue > 321 or qValue < 0 or qValue > 256: return -1
  let n = int(nValue)
  let q = int(qValue)
  if (n == 0 and q != 0) or length != csize_t(2 + n + q): return -1
  let queryStart = 2 + n
  for j in 0 ..< q:
    let index = input[queryStart + j]
    if index < 0 or index >= nValue: return -1

  var data: array[352, int64]
  var pointers: array[56, int64]
  var previousHeader: array[3, int64] = [-1'i64, -1'i64, -1'i64]
  var currentHeader = 0
  for pointer in pointers.mitems: pointer = -1
  for i in 0 ..< n:
    if i == 64 or i == 320:
      let nextHeader = currentHeader + 1
      previousHeader[nextHeader] = int64(currentHeader)
      currentHeader = nextHeader
    let location = locate(currentHeader, i)
    if pointers[location.pointerSlot] == -1:
      pointers[location.pointerSlot] = int64(location.childBase)
    if pointers[location.pointerSlot] != int64(location.childBase)
        or location.childBase + location.elementOffset >= data.len: return -1
    data[int(pointers[location.pointerSlot]) + location.elementOffset] = input[2 + i]

  let outputBytes = 8 * (q + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  putI64Le(output, 0, qValue)
  for j in 0 ..< q:
    let index = int(input[queryStart + j])
    let level = findLevel(index, currentHeader, previousHeader)
    let location = locate(level, index)
    let base = int(pointers[location.pointerSlot])
    putI64Le(output, 8 * (j + 1), data[base + location.elementOffset])
  int64(outputBytes)
