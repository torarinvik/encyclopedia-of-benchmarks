const InvalidResult = -1'i64
const OutputError = -2'i64
const InputLength = 6
const MaxParseableInputLength = 7

proc inRange(value, minimum, maximum: float64): bool =
  value >= minimum and value <= maximum

proc sir*(input: ptr UncheckedArray[float64], inputLength: csize_t,
          output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sir".} =
  if input.isNil or inputLength < InputLength.csize_t or
      inputLength > MaxParseableInputLength.csize_t:
    return InvalidResult
  if inputLength != InputLength.csize_t:
    return InvalidResult

  let s = input[0]
  let i = input[1]
  let r = input[2]
  let beta = input[3]
  let k = input[4]
  let time = input[5]
  if not inRange(s, 0.0, 1_000_000.0) or not inRange(i, 0.0, 1_000_000.0) or
      not inRange(r, 0.0, 1_000_000.0) or not inRange(beta, 0.0, 0.001) or
      not inRange(k, 0.0, 1.0) or not inRange(time, 0.0, 140.0):
    return InvalidResult

  let dS = ((-beta) * s) * i
  let dIInfection = (beta * s) * i
  let dIRecovery = k * i
  let dI = dIInfection - dIRecovery
  let dR = k * i

  if output.isNil or outputCapacity < 3.csize_t:
    return OutputError
  output[0] = dS
  output[1] = dI
  output[2] = dR
  3
