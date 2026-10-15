## Clear low set bits from the upper endpoint until it meets the lower endpoint.
proc range_bitwise_and*(left, right: uint64): int64 {.cdecl, exportc: "range_bitwise_and".} =
  if left > right or right > 2_147_483_647'u64: return -1
  var upper = right
  while left < upper:
    upper = upper and (upper - 1'u64)
  int64(upper)
