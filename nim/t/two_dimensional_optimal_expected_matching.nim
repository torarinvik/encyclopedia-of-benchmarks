const MaxSide = 12
const MaxCells = MaxSide * MaxSide
const MaxSamples = MaxCells
const MaxInputLength = 2 + 2 * MaxCells
const MaxParseableInputLength = MaxInputLength + 1

proc sampleCode(input: ptr UncheckedArray[int64], base, side, row, column,
                count, stride: int): int =
  var code = 0
  for offset in 0 ..< count:
    let at = base + row * side + column + offset * stride
    code = 4 * code + int(input[at])
  code

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc two_dimensional_optimal_expected_matching*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "two_dimensional_optimal_expected_matching".} =
  if input.isNil or length < 3 or length > csize_t(MaxParseableInputLength):
    return -1

  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxSide or mValue < 1 or mValue > nValue:
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
  var next: array[MaxSamples, int]
  var addressRow: array[MaxSamples, uint8]
  var addressColumn: array[MaxSamples, uint8]
  var addressCount = 0
  for row in 0 ..< m:
    for residue in 0 ..< stride:
      let code = sampleCode(input, patternBase, m, row, residue, q, stride)
      addressRow[addressCount] = uint8(row)
      addressColumn[addressCount] = uint8(residue)
      next[addressCount] = heads[code]
      heads[code] = addressCount
      inc addressCount

  var tested: array[MaxCells, bool]
  var matched: array[MaxCells, bool]
  let rowStarts = n - m + 1
  let columnStarts = n - m + 1
  var textRow = 0
  while textRow < n:
    var textColumn = 0
    while textColumn + finalOffset < n:
      let code = sampleCode(input, 2, n, textRow, textColumn, q, stride)
      var address = heads[code]
      while address >= 0:
        let slot = address
        let candidateRow = textRow - int(addressRow[slot])
        let candidateColumn = textColumn - int(addressColumn[slot])
        if candidateRow >= 0 and candidateColumn >= 0
            and candidateRow < rowStarts and candidateColumn < columnStarts:
          let candidate = candidateRow * n + candidateColumn
          if not tested[candidate]:
            tested[candidate] = true
            var equal = true
            for patternRow in 0 ..< m:
              for patternColumn in 0 ..< m:
                let textAt = 2 + (candidateRow + patternRow) * n + candidateColumn + patternColumn
                let patternAt = patternBase + patternRow * m + patternColumn
                if input[textAt] != input[patternAt]:
                  equal = false
                  break
              if not equal:
                break
            matched[candidate] = equal
        address = next[slot]
      textColumn += stride
    textRow += m

  var matchCount = 0
  for row in 0 ..< rowStarts:
    for column in 0 ..< columnStarts:
      if matched[row * n + column]:
        inc matchCount

  let outputBytes = 8 * (1 + 2 * matchCount)
  if output.isNil or capacity < csize_t(outputBytes):
    return -2
  putI64Le(output, 0, int64(matchCount))
  var outputWord = 1
  for row in 0 ..< rowStarts:
    for column in 0 ..< columnStarts:
      if not matched[row * n + column]:
        continue
      putI64Le(output, 8 * outputWord, int64(row))
      inc outputWord
      putI64Le(output, 8 * outputWord, int64(column))
      inc outputWord
  int64(outputBytes)
