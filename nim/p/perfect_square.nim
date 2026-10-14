## Exact perfect-square check using integer binary search and division.
proc perfect_square*(input: int64): int64 {.cdecl, exportc: "perfect_square".} =
  if input < 0:
    return 0
  if input < 2:
    return 1
  let number = uint64(input)
  var low = 1'u64
  var high = number div 2
  while low <= high:
    let middle = low + (high - low) div 2
    let quotient = number div middle
    if quotient == middle:
      if number mod middle == 0:
        return 1
      low = middle + 1
    elif quotient < middle:
      high = middle - 1
    else:
      low = middle + 1
  0
