## Bounded clean-room TAR-header filename search benchmark.
## Embench-IoT source declares MIT; see the package attribution.
## SPDX-License-Identifier: MIT
const
  MaxRecords = 35
  MaxQueries = 5
  MinNameLength = 5
  MaxNameLength = 39
  MaxInputLength = 2 + MaxRecords * (1 + MaxNameLength) + MaxQueries * (1 + MaxNameLength)

proc tarfind*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tarfind".} =
  if input.isNil or inputLength < 2 or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > int64(MaxRecords) or
      input[1] < 1 or input[1] > int64(MaxQueries): return -1
  let recordCount = int(input[0])
  let queryCount = int(input[1])
  var recordOffsets: array[MaxRecords, int]
  var recordLengths: array[MaxRecords, int]
  var queryOffsets: array[MaxQueries, int]
  var queryLengths: array[MaxQueries, int]
  var staged: array[MaxQueries, uint8]
  let total = int(inputLength)
  var position = 2

  for i in 0 ..< recordCount:
    if position >= total: return -1
    let rawLength = input[position]
    inc position
    if rawLength < int64(MinNameLength) or rawLength > int64(MaxNameLength): return -1
    let nameLength = int(rawLength)
    if nameLength > total - position: return -1
    recordOffsets[i] = position
    recordLengths[i] = nameLength
    for j in 0 ..< nameLength:
      if input[position + j] < 65 or input[position + j] > 90: return -1
    position += nameLength

  for i in 0 ..< queryCount:
    if position >= total: return -1
    let rawLength = input[position]
    inc position
    if rawLength < int64(MinNameLength) or rawLength > int64(MaxNameLength): return -1
    let nameLength = int(rawLength)
    if nameLength > total - position: return -1
    queryOffsets[i] = position
    queryLengths[i] = nameLength
    for j in 0 ..< nameLength:
      if input[position + j] < 65 or input[position + j] > 90: return -1
    position += nameLength
  if position != total: return -1
  if output.isNil or outputCapacity < csize_t(queryCount): return -2

  for q in 0 ..< queryCount:
    var found = -1
    for i in 0 ..< recordCount:
      if recordLengths[i] != queryLengths[q]: continue
      var j = 0
      while j < queryLengths[q] and input[recordOffsets[i] + j] == input[queryOffsets[q] + j]:
        inc j
      if j == queryLengths[q]:
        found = i
        break
    staged[q] = if found < 0: 255'u8 else: uint8(found)
  for q in 0 ..< queryCount:
    output[q] = staged[q]
  int64(queryCount)
