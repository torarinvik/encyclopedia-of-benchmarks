const
  MaxTarget = 127
  MaxInputLength = 2

type I64Input = ptr UncheckedArray[int64]

proc race_car_minimum_instruction_count*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "race_car_minimum_instruction_count".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  if length != csize_t(1): return -1
  let targetValue = input[0]
  if targetValue < 0 or targetValue > MaxTarget: return -1
  let target = int(targetValue)
  var distance: array[128, int32]

  var position = 1
  while position <= target:
    var run = 0
    var upperPower = 1
    while upperPower <= position:
      upperPower *= 2
      inc run
    let upper = upperPower - 1
    if position == upper:
      distance[position] = int32(run)
    else:
      var best = int32(run + 1) + distance[upper - position]
      let lower = upperPower div 2 - 1
      var backwardRun = 0
      var backwardPower = 1
      while backwardRun + 1 < run:
        let backwardDistance = backwardPower - 1
        let remaining = position - (lower - backwardDistance)
        let candidate = int32(run + backwardRun + 1) + distance[remaining]
        if candidate < best: best = candidate
        backwardPower *= 2
        inc backwardRun
      distance[position] = best
    inc position
  int64(distance[target])
