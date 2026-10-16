proc sum_multiples_inclusion_exclusion*(limit: int64): int64 {.cdecl, exportc: "sum_multiples_inclusion_exclusion".} =
  if limit < 1 or limit > 100_000:
    return -1
  let last = limit - 1
  let threes = last div 3
  let fives = last div 5
  let fifteens = last div 15
  return 3 * threes * (threes + 1) div 2 + 5 * fives * (fives + 1) div 2 - 15 * fifteens * (fifteens + 1) div 2
