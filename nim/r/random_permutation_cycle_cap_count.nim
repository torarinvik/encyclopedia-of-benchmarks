proc random_permutation_cycle_cap_count*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64 {.cdecl, exportc: "random_permutation_cycle_cap_count".} =
  if input == nil or inputLength != 2: return -1
  let n = input[0]
  let cap = input[1]
  if n < 1 or n > 20 or cap < 1 or cap > n: return -1

  var counts: array[21, int64]
  counts[0] = 1
  for size in 1 .. int(n):
    var total = 0'i64
    var cycleChoices = 1'i64
    let limit = min(size, int(cap))
    for cycleLength in 1 .. limit:
      if cycleLength > 1:
        cycleChoices *= int64(size - cycleLength + 1)
      total += cycleChoices * counts[size - cycleLength]
    counts[size] = total
  counts[int(n)]
