const MaxStates = 8
const MaxSteps = 64
const MaxInput = 267
const MaxOutput = 65

proc metropolis_hastings_asymmetric_proposal*(input: ptr UncheckedArray[int64],
    inputLength: csize_t, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "metropolis_hastings_asymmetric_proposal".} =
  if input.isNil or inputLength < csize_t(3) or inputLength > csize_t(MaxInput): return -1
  let n64 = input[0]
  let steps64 = input[1]
  let initial64 = input[2]
  if n64 < 2 or n64 > MaxStates or steps64 < 0 or steps64 > MaxSteps or
      initial64 < 0 or initial64 >= n64: return -1
  let n = int(n64)
  let steps = int(steps64)
  let weightsStart = 3
  let matrixStart = weightsStart + n
  let proposalsStart = matrixStart + n*n
  let drawsStart = proposalsStart + steps
  if int(inputLength) != drawsStart + 2*steps: return -1
  for state in 0 ..< n:
    if input[weightsStart + state] < 1 or input[weightsStart + state] > 1024: return -1
  for row in 0 ..< n:
    var rowSum = 0'i64
    for column in 0 ..< n:
      let probability = input[matrixStart + row*n + column]
      if probability < 0 or probability > 1024: return -1
      rowSum += probability
    if rowSum != 1024: return -1

  var staged: array[MaxOutput, uint8]
  var current = int(initial64)
  staged[0] = uint8(current)
  for step in 0 ..< steps:
    let proposal64 = input[proposalsStart + step]
    let drawNum = input[drawsStart + 2*step]
    let drawDen = input[drawsStart + 2*step + 1]
    if proposal64 < 0 or proposal64 >= n64 or drawDen < 1 or drawDen > 1024 or
        drawNum < 0 or drawNum >= drawDen: return -1
    let proposal = int(proposal64)
    let forward = input[matrixStart + current*n + proposal]
    if forward == 0: return -1
    let reverse = input[matrixStart + proposal*n + current]
    let numerator = input[weightsStart + proposal] * reverse
    let denominator = input[weightsStart + current] * forward
    if numerator >= denominator or drawNum*denominator < drawDen*numerator:
      current = proposal
    staged[step + 1] = uint8(current)

  let needed = steps + 1
  if output.isNil or outputCapacity < csize_t(needed): return -2
  for index in 0 ..< needed: output[index] = staged[index]
  int64(needed)
