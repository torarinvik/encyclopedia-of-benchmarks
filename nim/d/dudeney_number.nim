## Test whether n is a positive Dudeney number: cube root equals digit sum.
proc dudeney_number*(number: int64): int64 {.cdecl, exportc: "dudeney_number".} =
  if number <= 0 or number > int64(high(int32)): return -1
  var low = 1'i64
  var high = 1290'i64
  var root = 0'i64
  while low <= high:
    let middle = low + (high - low) div 2
    let cube = middle * middle * middle
    if cube == number:
      root = middle
      break
    if cube < number: low = middle + 1
    else: high = middle - 1
  if root == 0: return 0
  var remaining = number
  var sum = 0'i64
  while remaining > 0:
    sum += remaining mod 10
    remaining = remaining div 10
  if sum == root: 1 else: 0
