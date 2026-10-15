## Check whether a square can be split into two parts that sum to n.
proc kaprekar_number*(number: int64): int64 {.cdecl, exportc: "kaprekar_number".} =
  if number < 1: return 0
  if number > 2_000_000_000'i64: return -1
  if number == 1: return 1
  let square = number * number
  var split = 10'i64
  while split <= square:
    let right = square mod split
    if right > 0 and square div split + right == number: return 1
    if split > square div 10: break
    split *= 10
  0
