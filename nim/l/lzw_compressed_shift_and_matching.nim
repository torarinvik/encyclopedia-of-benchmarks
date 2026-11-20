const MaxAlphabet = 16
const MaxPattern = 32
const MaxCodes = 32
const MaxDictionary = 47
const MaxExpanded = 528
const MaxInput = 67
const MaxOutputBytes = 4232

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc lzw_compressed_shift_and_matching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lzw_compressed_shift_and_matching".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let alphabetRaw = input[0]
  let patternRaw = input[1]
  let codeCountRaw = input[2]
  if alphabetRaw < 1 or alphabetRaw > MaxAlphabet or patternRaw < 1 or patternRaw > MaxPattern
      or codeCountRaw < 0 or codeCountRaw > MaxCodes: return -1
  let alphabetSize = int(alphabetRaw)
  let patternLength = int(patternRaw)
  let codeCount = int(codeCountRaw)
  if int(length) != 3 + patternLength + codeCount: return -1
  var symbolMask: array[MaxAlphabet, uint32]
  for i in 0 ..< patternLength:
    let symbol = input[3 + i]
    if symbol < 0 or symbol >= alphabetRaw: return -1
    symbolMask[int(symbol)] = symbolMask[int(symbol)] or (uint32(1) shl i)
  if codeCount > 0 and (input[3 + patternLength] < 0 or input[3 + patternLength] >= alphabetRaw): return -1

  var phraseLength: array[MaxDictionary, int]
  var firstSymbol: array[MaxDictionary, uint8]
  var phraseMask: array[MaxDictionary, uint32]
  var crossingMask: array[MaxDictionary, uint32]
  var endsMatch: array[MaxDictionary, bool]
  var previousMatch: array[MaxDictionary, int]
  let topBit = uint32(1) shl (patternLength - 1)
  for symbol in 0 ..< alphabetSize:
    phraseLength[symbol] = 1
    firstSymbol[symbol] = uint8(symbol)
    phraseMask[symbol] = symbolMask[symbol]
    if patternLength > 1 and (phraseMask[symbol] and topBit) != 0:
      crossingMask[symbol] = uint32(1) shl (patternLength - 2)
    endsMatch[symbol] = patternLength == 1 and (phraseMask[symbol] and topBit) != 0
    previousMatch[symbol] = -1

  var words: array[1 + MaxExpanded, int64]
  var occurrenceCount = 0
  var nodeCount = alphabetSize
  var textOffset = 0
  var state = 0'u32
  var previousCode = -1
  for token in 0 ..< codeCount:
    let codeRaw = input[3 + patternLength + token]
    var currentCode = 0
    if previousCode < 0:
      currentCode = int(codeRaw)
    else:
      if codeRaw < 0 or codeRaw > int64(nodeCount): return -1
      var appended: uint8
      if codeRaw == int64(nodeCount):
        appended = firstSymbol[previousCode]
        currentCode = nodeCount
      else:
        currentCode = int(codeRaw)
        appended = firstSymbol[currentCode]
      if nodeCount >= MaxDictionary: return -1
      let node = nodeCount
      inc nodeCount
      phraseLength[node] = phraseLength[previousCode] + 1
      firstSymbol[node] = firstSymbol[previousCode]
      phraseMask[node] = ((phraseMask[previousCode] shl 1) or 1'u32) and symbolMask[int(appended)]
      crossingMask[node] = crossingMask[previousCode]
      if phraseLength[node] < patternLength and (phraseMask[node] and topBit) != 0:
        crossingMask[node] = crossingMask[node] or
          (uint32(1) shl (patternLength - phraseLength[node] - 1))
      endsMatch[node] = phraseLength[node] >= patternLength and (phraseMask[node] and topBit) != 0
      previousMatch[node] = if endsMatch[previousCode]: previousCode else: previousMatch[previousCode]

    var crossing = state and crossingMask[currentCode]
    while crossing != 0:
      var highest = 0
      var bits = crossing
      while (bits shr 1) != 0:
        bits = bits shr 1
        inc highest
      words[1 + occurrenceCount] = int64(textOffset - highest - 1)
      inc occurrenceCount
      crossing = crossing and not (uint32(1) shl highest)

    var internalNodes: array[MaxDictionary, int]
    var internalCount = 0
    var node = if endsMatch[currentCode]: currentCode else: previousMatch[currentCode]
    while node >= 0:
      internalNodes[internalCount] = node
      inc internalCount
      node = previousMatch[node]
    while internalCount > 0:
      dec internalCount
      node = internalNodes[internalCount]
      words[1 + occurrenceCount] = int64(textOffset + phraseLength[node] - patternLength)
      inc occurrenceCount

    let currentLength = phraseLength[currentCode]
    var shifted = 0'u32
    if currentLength < patternLength: shifted = state shl currentLength
    var fresh: uint32
    if currentLength >= patternLength:
      fresh = if patternLength == 32: high(uint32) else: (uint32(1) shl patternLength) - 1'u32
    else:
      fresh = (uint32(1) shl currentLength) - 1'u32
    state = (shifted or fresh) and phraseMask[currentCode]
    textOffset += currentLength
    previousCode = currentCode

  words[0] = int64(occurrenceCount)
  let outputBytes = csize_t(8 * (1 + occurrenceCount))
  if output.isNil or capacity < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for word in 0 ..< 1 + occurrenceCount: storeI64Le(addr staged[0], 8 * word, words[word])
  for byte in 0 ..< int(outputBytes): output[byte] = staged[byte]
  int64(outputBytes)
