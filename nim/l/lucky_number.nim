const MaxInput = 1_000_000'i64

## Preserve the pinned Java rank loop, including counter += 1 each round.
proc lucky_number*(number: int64): int64 {.cdecl, exportc: "lucky_number".} =
  if number < 1 or number > MaxInput: return -1
  var counter = 2'i64
  var position = number
  while counter <= position:
    if position mod counter == 0: return 0
    position -= position div counter
    inc counter
  1
