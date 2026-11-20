const KmMaxSide = 12
const KmMaxCells = KmMaxSide * KmMaxSide
const KmMaxParseableInputLength = 2 + 2 * KmMaxCells + 1

proc kmSampleCode(input: ptr UncheckedArray[int64], base, side, row, column,
                  q, stride: int): int =
  var code = 0
  for step in 0 ..< q:
    let at = base + row * side + column + step * stride
    code = 4 * code + int(input[at])
  code

proc kmPutI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc two_dimensional_k_mismatch_linear_templates*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "two_dimensional_k_mismatch_linear_templates".} =
  if input.isNil or length < 3 or length > csize_t(KmMaxParseableInputLength):
    return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 3 or nValue > KmMaxSide or mValue < 3 or mValue > nValue:
    return -1
  let n = int(nValue)
  let m = int(mValue)
  let textSize = n * n
  let patternSize = m * m
  if int(length) != 2 + textSize + patternSize:
    return -1
  let patternBase = 2 + textSize
  for index in 0 ..< textSize + patternSize:
    let value = input[2 + index]
    if value < 0 or value > 3:
      return -1

  var q = 1
  var codeCapacity = 4
  while codeCapacity < patternSize:
    inc q
    codeCapacity *= 4
  let stride = m div q
  let finalOffset = (q - 1) * stride
  var heads: array[256, int]
  for code in 0 ..< heads.len:
    heads[code] = -1
  var next: array[KmMaxCells, int]
  var sampleRow: array[KmMaxCells, uint8]
  var sampleColumn: array[KmMaxCells, uint8]
  var sampleCount = 0
  for row in 0 ..< m:
    for residue in 0 ..< stride:
      let code = kmSampleCode(input, patternBase, m, row, residue, q, stride)
      sampleRow[sampleCount] = uint8(row)
      sampleColumn[sampleCount] = uint8(residue)
      next[sampleCount] = heads[code]
      heads[code] = sampleCount
      inc sampleCount

  var considered: array[KmMaxCells, bool]
  var matched: array[KmMaxCells, bool]
  let starts = n - m + 1
  for textRow in 0 ..< n:
    if textRow mod m < m - 2:
      continue
    var textColumn = 0
    while textColumn + finalOffset < n:
      let code = kmSampleCode(input, 2, n, textRow, textColumn, q, stride)
      var address = heads[code]
      while address >= 0:
        let slot = address
        let candidateRow = textRow - int(sampleRow[slot])
        let candidateColumn = textColumn - int(sampleColumn[slot])
        if candidateRow >= 0 and candidateColumn >= 0 and
            candidateRow < starts and candidateColumn < starts:
          let candidate = candidateRow * n + candidateColumn
          if not considered[candidate]:
            considered[candidate] = true
            var mismatches = 0
            for dr in 0 ..< m:
              for dc in 0 ..< m:
                let textAt = 2 + (candidateRow + dr) * n + candidateColumn + dc
                let patternAt = patternBase + dr * m + dc
                if input[textAt] != input[patternAt]:
                  inc mismatches
                  if mismatches == 2:
                    break
              if mismatches == 2:
                break
            matched[candidate] = mismatches <= 1
        address = next[slot]
      textColumn += stride

  var matchCount = 0
  for row in 0 ..< starts:
    for column in 0 ..< starts:
      if matched[row * n + column]:
        inc matchCount
  let outputBytes = 8 * (1 + 2 * matchCount)
  if output.isNil or capacity < csize_t(outputBytes):
    return -2
  kmPutI64Le(output, 0, int64(matchCount))
  var word = 1
  for row in 0 ..< starts:
    for column in 0 ..< starts:
      if matched[row * n + column]:
        kmPutI64Le(output, 8 * word, int64(row))
        inc word
        kmPutI64Le(output, 8 * word, int64(column))
        inc word
  int64(outputBytes)
