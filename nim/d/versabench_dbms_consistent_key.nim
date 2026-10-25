proc versabench_dbms_consistent_key*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_consistent_key".} =
  if values == nil or length < 1 or length > 17 or length != 16: return -1
  for box in 0 ..< 2:
    let base = box * 8
    for d in 0 ..< 4:
      let lower = values[base+d]; let upper = values[base+4+d]
      if lower < -8 or lower > 8 or upper < -8 or upper > 8 or lower > upper: return -1
  for d in 0 ..< 4:
    if values[d] > values[12+d] or values[8+d] > values[4+d]: return 0
  1
