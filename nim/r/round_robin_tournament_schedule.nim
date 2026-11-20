const MaxTeams = 8
const MaxParseableInput = 2
const MaxCells = 64

proc round_robin_tournament_schedule*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "round_robin_tournament_schedule".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableInput): return -1
  if length != 1: return -1
  let nWord = input[0]
  if nWord < 2 or nWord > MaxTeams.int64: return -1

  let n = int(nWord)
  let padded = n + (n mod 2)
  let ringSize = padded - 1
  let rounds = ringSize
  let fixed = padded - 1
  var table: array[MaxCells, uint8]
  for i in 0 ..< MaxCells: table[i] = 255'u8

  for round in 0 ..< rounds:
    if fixed < n:
      table[fixed * rounds + round] = uint8(round)
      table[round * rounds + round] = uint8(fixed)
    for offset in 1 ..< (padded div 2):
      let left = (round + offset) mod ringSize
      let right = (round + ringSize - offset) mod ringSize
      if left < n and right < n:
        table[left * rounds + round] = uint8(right)
        table[right * rounds + round] = uint8(left)

  let required = 2 + n * rounds
  if output.isNil or capacity < csize_t(required): return -2
  output[0] = uint8(n)
  output[1] = uint8(rounds)
  for i in 0 ..< n * rounds: output[i + 2] = table[i]
  int64(required)
