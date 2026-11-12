type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc fkmGenerate(position, period, order, alphabet: int,
    work: var array[17, uint8], output: U8Output, emitted: var int) =
  if position > order:
    if order mod period == 0:
      for index in 1..period:
        output[emitted] = uint8(48 + int(work[index]))
        inc emitted
    return
  work[position] = work[position - period]
  fkmGenerate(position + 1, period, order, alphabet, work, output, emitted)
  for symbol in int(work[position - period]) + 1 ..< alphabet:
    work[position] = uint8(symbol)
    fkmGenerate(position + 1, position, order, alphabet, work, output, emitted)

proc de_bruijn_sequences*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "de_bruijn_sequences".} =
  const MaxCycleLength = 10000
  if input == nil or length != 2: return -1
  let alphabetValue = input[0]
  let orderValue = input[1]
  if alphabetValue < 2 or alphabetValue > 10 or orderValue < 1 or orderValue > 16: return -1
  let alphabet = int(alphabetValue)
  let order = int(orderValue)
  var cycleLength = 1
  for _ in 0..<order:
    if cycleLength > MaxCycleLength div alphabet: return -1
    cycleLength *= alphabet
  let outputLength = cycleLength + order - 1
  if outputCapacity < csize_t(outputLength) or output == nil: return -2
  var work: array[17, uint8]
  var emitted = 0
  fkmGenerate(1, 1, order, alphabet, work, output, emitted)
  for index in 0..<(order - 1):
    output[csize_t(cycleLength + index)] = output[csize_t(index)]
  int64(outputLength)
