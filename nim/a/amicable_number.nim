proc proper_divisor_sum(number: uint64): uint64 =
  if number <= 1'u64:
    return 0
  var sum = 1'u64
  var divisor = 2'u64
  while divisor <= number div divisor:
    if number mod divisor == 0:
      sum += divisor
      let partner = number div divisor
      if partner != divisor:
        sum += partner
    inc divisor
  return sum

proc amicable_number*(left, right: uint64): int64 {.cdecl, exportc: "amicable_number".} =
  if left < 1'u64 or left > 1_000_000_000'u64 or right < 1'u64 or right > 1_000_000_000'u64:
    return -1
  if left == right:
    return 0
  return int64(proper_divisor_sum(left) == right and proper_divisor_sum(right) == left)
