const MaxText = 12
const MaxInput = 14
const MaxOutput = 1592

proc editDistance(input: ptr UncheckedArray[int64], a, aLength, b, bLength: int): int =
  var row: array[MaxText + 1, int]
  for j in 0 .. bLength: row[j] = j
  for i in 1 .. aLength:
    var diagonal = row[0]
    row[0] = i
    for j in 1 .. bLength:
      let above = row[j]
      let deletion = above + 1
      let insertion = row[j - 1] + 1
      let substitution = diagonal + int(input[2 + a + i - 1] != input[2 + b + j - 1])
      row[j] = min(min(deletion, insertion), substitution)
      diagonal = above
  row[bLength]

proc minimumEditCost(input: ptr UncheckedArray[int64], start, factorLength: int): int =
  result = 1000
  var pieceStarts, pieceLengths: array[MaxText, int]
  for prefix in 0 .. factorLength:
    for suffix in 0 .. factorLength - prefix:
      let middle = factorLength - prefix - suffix
      if middle < 2: continue
      let endMask = 1 shl (middle - 1)
      for mask in 1 ..< endMask:
        var segments = 0
        var previous = 0
        for cut in 1 ..< middle:
          if (mask and (1 shl (cut - 1))) != 0:
            pieceStarts[segments] = start + prefix + previous
            pieceLengths[segments] = cut - previous
            inc segments
            previous = cut
        pieceStarts[segments] = start + prefix + previous
        pieceLengths[segments] = middle - previous
        inc segments
        var left = 1000
        for fragment in 0 .. pieceLengths[0]:
          left = min(left, editDistance(input, start, prefix,
            pieceStarts[0] + pieceLengths[0] - fragment, fragment))
        let last = segments - 1
        var right = 1000
        for fragment in 0 .. pieceLengths[last]:
          right = min(right, editDistance(input, pieceStarts[last], fragment,
            start + factorLength - suffix, suffix))
        var internal = 0
        for i in 0 ..< segments - 1:
          internal += editDistance(input, pieceStarts[i], pieceLengths[i],
                                   pieceStarts[i + 1], pieceLengths[i + 1])
        result = min(result, left + internal + right)

proc recordCount(input: ptr UncheckedArray[int64], n, budget: int): int =
  for start in 0 ..< n:
    for factorLength in 2 .. n - start:
      if minimumEditCost(input, start, factorLength) <= budget: inc result

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc approximate_tandem_k_edit_repeats*(input: ptr UncheckedArray[int64], length: csize_t,
                                       output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "approximate_tandem_k_edit_repeats".} =
  if input.isNil or length < 4 or length > MaxInput: return -1
  let n0 = input[0]
  let budget0 = input[1]
  if n0 < 2 or n0 > MaxText or budget0 < 0 or budget0 > 4 or int(length) != int(n0) + 2: return -1
  let n = int(n0)
  let budget = int(budget0)
  for i in 0 ..< n:
    if input[2 + i] < 0 or input[2 + i] > 3: return -1
  let count = recordCount(input, n, budget)
  let bytes = 8 * (1 + 3 * count)
  if bytes > MaxOutput: return -1
  if output.isNil or int(capacity) < bytes: return -2
  storeI64Le(output, 0, int64(count))
  var record = 0
  for start in 0 ..< n:
    for factorLength in 2 .. n - start:
      let cost = minimumEditCost(input, start, factorLength)
      if cost <= budget:
        let offset = 8 * (1 + 3 * record)
        storeI64Le(output, offset, int64(start))
        storeI64Le(output, offset + 8, int64(factorLength))
        storeI64Le(output, offset + 16, int64(cost))
        inc record
  int64(bytes)
