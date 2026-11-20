const MaxDim = 5
const MaxPatDim = 4
const MaxInput = 196
const MaxMatches = 125

proc putLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc sameRows(plane: array[MaxPatDim * MaxPatDim, int64], left, right, width: int): bool =
  for column in 0..<width:
    if plane[left * width + column] != plane[right * width + column]: return false
  true

proc three_dimensional_bird_baker_matching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"three_dimensional_bird_baker_matching".} =
  if input.isNil or length < 7 or length > csize_t(MaxInput): return -1
  let r0, c0, d0 = input[0], input[1], input[2]
  let pr0, pc0, pd0 = input[3], input[4], input[5]
  if r0 < 1 or r0 > 5 or c0 < 1 or c0 > 5 or d0 < 1 or d0 > 5
      or pr0 < 1 or pr0 > 4 or pc0 < 1 or pc0 > 4 or pd0 < 1 or pd0 > 4
      or pr0 > r0 or pc0 > c0 or pd0 > d0: return -1
  let rows, columns, depths = int(r0), int(c0), int(d0)
  let pRows, pColumns, pDepths = int(pr0), int(pc0), int(pd0)
  let textSize = rows * columns * depths
  let patternSize = pRows * pColumns * pDepths
  if int(length) != 6 + textSize + patternSize: return -1
  var text: array[MaxDim * MaxDim * MaxDim, int64]
  var pattern: array[MaxPatDim * MaxPatDim * MaxPatDim, int64]
  for i in 0..<textSize:
    text[i] = input[6 + i]
    if text[i] < 0 or text[i] > 3: return -1
  for i in 0..<patternSize:
    pattern[i] = input[6 + textSize + i]
    if pattern[i] < 0 or pattern[i] > 3: return -1

  var planeIds: array[MaxPatDim, int]
  var uniquePlanes: array[MaxPatDim, array[MaxPatDim * MaxPatDim, int64]]
  let planeArea = pRows * pColumns
  var uniqueCount = 0
  for pz in 0..<pDepths:
    var found = uniqueCount
    for candidate in 0..<uniqueCount:
      var equal = true
      for i in 0..<planeArea:
        if uniquePlanes[candidate][i] != pattern[pz * planeArea + i]: equal = false
      if equal:
        found = candidate
        break
    if found == uniqueCount:
      for i in 0..<planeArea: uniquePlanes[uniqueCount][i] = pattern[pz * planeArea + i]
      inc uniqueCount
    planeIds[pz] = found

  let rowStarts = rows - pRows + 1
  let colStarts = columns - pColumns + 1
  var labels: array[MaxDim * MaxDim * MaxDim, int]
  for i in 0..<labels.len: labels[i] = -1
  for z in 0..<depths:
    for unique in 0..<uniqueCount:
      var marks: array[MaxDim * MaxDim * MaxPatDim, bool]
      var prefix: array[MaxPatDim, int]
      for i in 1..<pRows:
        var matched = prefix[i - 1]
        while matched > 0 and not sameRows(uniquePlanes[unique], i, matched, pColumns):
          matched = prefix[matched - 1]
        if sameRows(uniquePlanes[unique], i, matched, pColumns): inc matched
        prefix[i] = matched
      for row in 0..<rows:
        for col in 0..<colStarts:
          for pRow in 0..<pRows:
            var equal = true
            for pCol in 0..<pColumns:
              if text[(z * rows + row) * columns + col + pCol]
                  != uniquePlanes[unique][pRow * pColumns + pCol]: equal = false
            marks[(row * MaxDim + col) * MaxPatDim + pRow] = equal
      for col in 0..<colStarts:
        var matched = 0
        for row in 0..<rows:
          while matched > 0 and not marks[(row * MaxDim + col) * MaxPatDim + matched]:
            matched = prefix[matched - 1]
          if marks[(row * MaxDim + col) * MaxPatDim + matched]: inc matched
          if matched == pRows:
            labels[(z * MaxDim + row + 1 - pRows) * MaxDim + col] = unique
            matched = prefix[matched - 1]

  var depthPrefix: array[MaxPatDim, int]
  for i in 1..<pDepths:
    var matched = depthPrefix[i - 1]
    while matched > 0 and planeIds[i] != planeIds[matched]: matched = depthPrefix[matched - 1]
    if planeIds[i] == planeIds[matched]: inc matched
    depthPrefix[i] = matched
  var matches: array[MaxMatches * 3, int64]
  var count = 0
  for row in 0..<rowStarts:
    for col in 0..<colStarts:
      var matched = 0
      for z in 0..<depths:
        let token = labels[(z * MaxDim + row) * MaxDim + col]
        while matched > 0 and token != planeIds[matched]: matched = depthPrefix[matched - 1]
        if token == planeIds[matched]: inc matched
        if matched == pDepths:
          matches[count * 3] = int64(row)
          matches[count * 3 + 1] = int64(col)
          matches[count * 3 + 2] = int64(z + 1 - pDepths)
          inc count
          matched = depthPrefix[matched - 1]
  let bytes = 8 * (1 + 3 * count)
  if output.isNil or int(capacity) < bytes: return -2
  putLe(output, 0, int64(count))
  for i in 0..<(3 * count): putLe(output, 8 * (i + 1), matches[i])
  int64(bytes)
