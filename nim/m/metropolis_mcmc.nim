import std/math

const MaxStates = 8
const MaxSteps = 64
const MaxInput = 140

proc boundedInteger(value, minimum, maximum: float64): bool =
  value.isFinite and floor(value) == value and value >= minimum and value <= maximum

proc metropolis_mcmc*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "metropolis_mcmc".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  if not boundedInteger(input[0], 1.0, float64(MaxStates)) or
      not boundedInteger(input[1], 0.0, float64(MaxSteps)): return -1
  let states = int(input[0])
  let steps = int(input[1])
  if not boundedInteger(input[2], 0.0, float64(states - 1)) or
      not input[3].isFinite or input[3] < 0.001 or input[3] > 1000.0 or
      length != csize_t(4 + states + 2 * steps): return -1
  for state in 0 ..< states:
    if not input[4 + state].isFinite or abs(input[4 + state]) > 1_000_000.0: return -1
  let proposalStart = 4 + states
  let uniformStart = proposalStart + steps
  for step in 0 ..< steps:
    if not boundedInteger(input[proposalStart + step], 0.0, float64(states - 1)): return -1
    let uniform = input[uniformStart + step]
    if not uniform.isFinite or uniform < 0.0 or uniform >= 1.0: return -1
  if output.isNil or capacity < csize_t(steps + 1): return -2

  var current = int(input[2])
  output[0] = float64(current)
  for step in 0 ..< steps:
    let proposal = int(input[proposalStart + step])
    let delta = (input[4 + proposal] - input[4 + current]) / input[3]
    if delta <= 0.0:
      current = proposal
    elif input[uniformStart + step] < exp(-delta):
      current = proposal
    output[step + 1] = float64(current)
  int64(steps + 1)
