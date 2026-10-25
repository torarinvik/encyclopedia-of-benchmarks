proc versabench_dbms_penalty*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_penalty".} =
  if values == nil or length < 1 or length > 17 or length != 16: return -1
  for box in 0 ..< 2:
    for d in 0 ..< 4:
      let lo = values[box*8+d]; let hi = values[box*8+4+d]
      if lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo >= hi: return -1
  var joined = 1'i64
  var original = 1'i64
  for d in 0 ..< 4:
    joined *= max(values[4+d], values[12+d]) - min(values[d], values[8+d])
    original *= values[4+d] - values[d]
  joined - original
