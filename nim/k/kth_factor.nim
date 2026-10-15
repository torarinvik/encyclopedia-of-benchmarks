proc kth_factor*(n_value, k_value: int64): int64 {.cdecl, exportc: "kth_factor".} =
  if n_value < 1 or n_value > 10000 or k_value < 1 or k_value > n_value: return -1
  let n = int32(n_value)
  let k = int32(k_value)
  var factors_found = 0'i32
  for i in 1'i32 .. n:
    if n mod i == 0:
      factors_found += 1
      if factors_found == k: return int64(i)
  return -1
