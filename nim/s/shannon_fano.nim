const MaxTextLength = 64
const MaxInputLength = 66
const MaxSymbols = 10
const MaxOutputBytes = 111

type Frame = object
  start, finish: int
  bits: uint16
  length: int

proc shannon_fano_generate_codes*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "shannon_fano_generate_codes".} =
  let nullEmpty = input.isNil and inputLength == 0
  if input.isNil and not nullEmpty: return -1
  var text: array[MaxTextLength, uint8]
  var textLength = 0
  if not nullEmpty:
    if inputLength < 1 or inputLength > csize_t(MaxInputLength): return -1
    let lengthValue = input[0]
    if lengthValue < 0 or lengthValue > MaxTextLength.int64: return -1
    textLength = int(lengthValue)
    if inputLength != csize_t(1 + textLength): return -1
    for index in 0 ..< textLength:
      let code = input[1 + index]
      if code < 0 or code > 127: return -1
      text[index] = uint8(code)

  var frequencies: array[128, int]
  for index in 0 ..< textLength: inc frequencies[int(text[index])]
  var symbols: array[128, int]
  var symbolCount = 0
  for symbol in 0 ..< 128:
    if frequencies[symbol] > 0:
      symbols[symbolCount] = symbol
      inc symbolCount
  if symbolCount > MaxSymbols: return -1
  for left in 0 ..< symbolCount:
    for right in left + 1 ..< symbolCount:
      if frequencies[symbols[left]] == frequencies[symbols[right]]: return -1
  for index in 1 ..< symbolCount:
    let value = symbols[index]
    var position = index
    while position > 0 and frequencies[symbols[position - 1]] < frequencies[value]:
      symbols[position] = symbols[position - 1]
      dec position
    symbols[position] = value

  var codeBits: array[128, uint16]
  var codeLengths: array[128, int]
  if symbolCount == 1:
    codeLengths[symbols[0]] = 1
  elif symbolCount > 1:
    var stack: array[20, Frame]
    var stackLength = 1
    stack[0] = Frame(start: 0, finish: symbolCount - 1, bits: 0, length: 0)
    while stackLength > 0:
      dec stackLength
      let frame = stack[stackLength]
      if frame.start == frame.finish:
        let symbol = symbols[frame.start]
        codeBits[symbol] = frame.bits
        codeLengths[symbol] = frame.length
        continue
      var total = 0
      for index in frame.start .. frame.finish: total += frequencies[symbols[index]]
      var leftSum = 0
      var bestDifference = high(int)
      var split = frame.start
      for index in frame.start ..< frame.finish:
        leftSum += frequencies[symbols[index]]
        let rightSum = total - leftSum
        let difference = abs(leftSum - rightSum)
        if difference < bestDifference:
          bestDifference = difference
          split = index
      let nextLength = frame.length + 1
      stack[stackLength] = Frame(start: split + 1, finish: frame.finish,
        bits: (frame.bits shl 1) or 1'u16, length: nextLength)
      inc stackLength
      stack[stackLength] = Frame(start: frame.start, finish: split,
        bits: frame.bits shl 1, length: nextLength)
      inc stackLength

  var bytes: array[MaxOutputBytes, uint8]
  var written = 0
  bytes[written] = uint8(symbolCount)
  inc written
  for symbol in 0 ..< 128:
    let codeLength = codeLengths[symbol]
    if codeLength == 0: continue
    bytes[written] = uint8(symbol)
    bytes[written + 1] = uint8(codeLength)
    written += 2
    for offset in 0 ..< codeLength:
      let bit = (codeBits[symbol] shr (codeLength - 1 - offset)) and 1'u16
      bytes[written] = uint8(ord('0')) + uint8(bit)
      inc written
  if output.isNil or outputCapacity < csize_t(written): return -2
  for index in 0 ..< written: output[index] = bytes[index]
  int64(written)
