const
  MaxOperations = 24
  MaxKeys = 24
  MapCount = 4
  MaxParseableInputLength = 98
  I32Min = -2_147_483_648'i64
  I32Max = 2_147_483_647'i64

proc lww_element_set*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64
    {.cdecl, exportc: "lww_element_set".} =
  if input == nil or inputLength < 1 or inputLength > csize_t(MaxParseableInputLength): return -1
  let operationCountValue = input[0]
  if operationCountValue < 0 or operationCountValue > MaxOperations: return -1
  let operationCount = int(operationCountValue)
  if int(inputLength) != 1 + 4 * operationCount: return -1

  var keys: array[MapCount * MaxKeys, int64]
  var timestamps: array[MapCount * MaxKeys, int64]
  var mapCounts: array[MapCount, int]
  var lookupMask: int64 = 0
  var lookupIndex = 0

  for operation in 0 ..< operationCount:
    let offset = 1 + 4 * operation
    let opcode = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    let third = input[offset + 3]
    if opcode == 0 or opcode == 1:
      if first < 0 or first > 1 or second < I32Min or second > I32Max or third < I32Min or third > I32Max:
        return -1
      let mapIndex = int(first) * 2 + (if opcode == 1: 1 else: 0)
      let base = mapIndex * MaxKeys
      var position = 0
      while position < mapCounts[mapIndex] and keys[base + position] != second: inc position
      if position == mapCounts[mapIndex]:
        if mapCounts[mapIndex] >= MaxKeys: return -1
        keys[base + position] = second
        inc mapCounts[mapIndex]
      timestamps[base + position] = third
    elif opcode == 2:
      if first < 0 or first > 1 or second < I32Min or second > I32Max or third != 0: return -1
      let addMap = int(first) * 2
      let addBase = addMap * MaxKeys
      let removeMap = addMap + 1
      let removeBase = removeMap * MaxKeys
      var addPosition = 0
      var removePosition = 0
      while addPosition < mapCounts[addMap] and keys[addBase + addPosition] != second: inc addPosition
      while removePosition < mapCounts[removeMap] and keys[removeBase + removePosition] != second: inc removePosition
      if addPosition < mapCounts[addMap] and
          (removePosition == mapCounts[removeMap] or
           timestamps[addBase + addPosition] > timestamps[removeBase + removePosition]):
        lookupMask = lookupMask or (1'i64 shl lookupIndex)
      inc lookupIndex
    elif opcode == 3:
      if first < 0 or first > 1 or second < 0 or second > 1 or third != 0: return -1
      if first != second:
        for kind in 0 ..< 2:
          let targetMap = int(first) * 2 + kind
          let sourceMap = int(second) * 2 + kind
          let targetBase = targetMap * MaxKeys
          let sourceBase = sourceMap * MaxKeys
          for sourcePosition in 0 ..< mapCounts[sourceMap]:
            let key = keys[sourceBase + sourcePosition]
            let timestamp = timestamps[sourceBase + sourcePosition]
            var targetPosition = 0
            while targetPosition < mapCounts[targetMap] and keys[targetBase + targetPosition] != key: inc targetPosition
            if targetPosition == mapCounts[targetMap]:
              if mapCounts[targetMap] >= MaxKeys: return -1
              keys[targetBase + targetPosition] = key
              timestamps[targetBase + targetPosition] = timestamp
              inc mapCounts[targetMap]
            elif timestamp >= timestamps[targetBase + targetPosition]:
              timestamps[targetBase + targetPosition] = timestamp
    else:
      return -1
  lookupMask
