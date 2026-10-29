const
  MaxN = 32
  MaxQ = 16
  MaxBlocks = 6
  MaxInputLength = 66

proc lowerBoundI64(values: openArray[int64], count: int, target: int64): int =
  var begin = 0
  var finish = count
  while begin < finish:
    let middle = begin + (finish - begin) div 2
    if values[middle] < target: begin = middle + 1
    else: finish = middle
  begin

proc lowerBoundInt(values: openArray[int], beginValue, endValue, target: int): int =
  var begin = beginValue
  var finish = endValue
  while begin < finish:
    let middle = begin + (finish - begin) div 2
    if values[middle] < target: begin = middle + 1
    else: finish = middle
  begin

proc rangeFrequency(occurrences: openArray[int], offsets: openArray[int],
                    id, left, right: int): int =
  let begin = offsets[id]
  let finish = offsets[id + 1]
  lowerBoundInt(occurrences, begin, finish, right) -
    lowerBoundInt(occurrences, begin, finish, left)

proc writeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc static_range_mode_query*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "static_range_mode_query".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > int64(MaxN) or qValue < 1 or qValue > int64(MaxQ): return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + n + 2 * q): return -1
  for index in 0 ..< n:
    if input[2 + index] < 0 or input[2 + index] > 1_000_000_000: return -1
  for query in 0 ..< q:
    let left = input[2 + n + 2 * query]
    let right = input[3 + n + 2 * query]
    if left < 0 or right <= left or right > nValue: return -1
  if output == nil or outputCapacity < csize_t(16 * q): return -2

  var sorted, uniqueValues: array[MaxN, int64]
  var compressed, frequencies, cursor, occurrences: array[MaxN, int]
  var offsets: array[MaxN + 1, int]
  var blockMode: array[MaxBlocks * MaxBlocks, int]
  for index in 0 ..< n:
    let value = input[2 + index]
    var position = index
    while position > 0 and sorted[position - 1] > value:
      sorted[position] = sorted[position - 1]
      dec position
    sorted[position] = value
  var distinct = 0
  for index in 0 ..< n:
    if distinct == 0 or sorted[index] != uniqueValues[distinct - 1]:
      uniqueValues[distinct] = sorted[index]
      inc distinct
  for index in 0 ..< n:
    let id = lowerBoundI64(uniqueValues, distinct, input[2 + index])
    compressed[index] = id
    inc frequencies[id]
  for id in 0 ..< distinct: offsets[id + 1] = offsets[id] + frequencies[id]
  for id in 0 ..< distinct: cursor[id] = offsets[id]
  for index in 0 ..< n:
    let id = compressed[index]
    occurrences[cursor[id]] = index
    inc cursor[id]

  var blockSize = 1
  while blockSize * blockSize < n: inc blockSize
  let blockCount = (n + blockSize - 1) div blockSize
  var frequency: array[MaxN, int]
  for first in 0 ..< blockCount:
    for id in 0 ..< distinct: frequency[id] = 0
    var bestId = 0
    var bestCount = 0
    for last in first ..< blockCount:
      let begin = last * blockSize
      let finish = min(n, begin + blockSize)
      for index in begin ..< finish:
        let id = compressed[index]
        inc frequency[id]
        let count = frequency[id]
        if count > bestCount or (count == bestCount and id < bestId):
          bestId = id
          bestCount = count
      blockMode[first * MaxBlocks + last] = bestId

  for query in 0 ..< q:
    let left = int(input[2 + n + 2 * query])
    let right = int(input[3 + n + 2 * query])
    let firstFull = (left + blockSize - 1) div blockSize
    let afterFull = right div blockSize
    var bestId = 0
    var bestCount = 0
    if firstFull < afterFull:
      bestId = blockMode[firstFull * MaxBlocks + afterFull - 1]
      bestCount = rangeFrequency(occurrences, offsets, bestId, left, right)
      let spanStart = firstFull * blockSize
      let spanEnd = afterFull * blockSize
      for index in left ..< spanStart:
        let id = compressed[index]
        let count = rangeFrequency(occurrences, offsets, id, left, right)
        if count > bestCount or (count == bestCount and id < bestId):
          bestId = id
          bestCount = count
      for index in spanEnd ..< right:
        let id = compressed[index]
        let count = rangeFrequency(occurrences, offsets, id, left, right)
        if count > bestCount or (count == bestCount and id < bestId):
          bestId = id
          bestCount = count
    else:
      for index in left ..< right:
        let id = compressed[index]
        let count = rangeFrequency(occurrences, offsets, id, left, right)
        if count > bestCount or (count == bestCount and id < bestId):
          bestId = id
          bestCount = count
    writeI64(output, 16 * query, uniqueValues[bestId])
    writeI64(output, 16 * query + 8, int64(bestCount))
  int64(16 * q)
