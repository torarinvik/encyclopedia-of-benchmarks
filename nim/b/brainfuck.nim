## Interpret a bounded Brainfuck byte program with portable limits.
proc brainfuck*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "brainfuck".} =
  const MaxProgram = 2048
  const MaxInput = 1024
  const MaxOutput = 8192
  const MaxSteps = 100000
  const TapeCells = 257
  if values == nil or length < 2 or length > MaxProgram + MaxInput + 2: return -2
  if values[0] < 0 or values[0] > MaxProgram: return -2
  let programLength = int(values[0])
  let inputLengthIndex = programLength + 1
  if csize_t(inputLengthIndex) >= length or values[inputLengthIndex] < 0 or values[inputLengthIndex] > MaxInput: return -2
  let inputLength = int(values[inputLengthIndex])
  if int(length) != programLength + inputLength + 2: return -2

  var matching: array[MaxProgram, int32]
  var openings: array[MaxProgram, int]
  for index in 0 ..< programLength:
    matching[index] = -1
    let byte = values[index + 1]
    if byte < 32 or byte > 126: return -2
  var depth = 0
  for index in 0 ..< programLength:
    case values[index + 1]
    of 91:
      openings[depth] = index
      inc depth
    of 93:
      if depth == 0: return -2
      dec depth
      let opening = openings[depth]
      matching[opening] = int32(index)
      matching[index] = int32(opening)
    else: discard
  if depth != 0: return -2
  for index in 0 ..< inputLength:
    let byte = values[inputLengthIndex + 1 + index]
    if byte < 0 or byte > 255: return -2

  var tape: array[TapeCells, uint8]
  var scratch: array[MaxOutput, uint8]
  var dataPointer = TapeCells div 2
  var inputIndex = 0
  var instruction = 0
  var steps = 0
  var outputLength = 0
  while instruction < programLength:
    inc steps
    if steps > MaxSteps: return -2
    case values[instruction + 1]
    of 46:
      if outputLength == MaxOutput: return -2
      scratch[outputLength] = tape[dataPointer]
      inc outputLength
    of 44:
      if inputIndex < inputLength:
        tape[dataPointer] = uint8(values[inputLengthIndex + 1 + inputIndex])
        inc inputIndex
      else:
        tape[dataPointer] = 0
    of 62:
      inc dataPointer
      if dataPointer >= TapeCells: return -2
    of 60:
      if dataPointer == 0: return -2
      dec dataPointer
    of 43: inc tape[dataPointer]
    of 45: dec tape[dataPointer]
    of 91:
      if tape[dataPointer] == 0: instruction = int(matching[instruction])
    of 93:
      if tape[dataPointer] != 0: instruction = int(matching[instruction])
    else: discard
    inc instruction
  if outputLength > int(outputCapacity) or (outputLength != 0 and output == nil): return -2
  for index in 0 ..< outputLength: output[index] = scratch[index]
  int64(outputLength)
