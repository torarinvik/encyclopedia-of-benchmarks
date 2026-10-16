proc palindromic_partitioning*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "palindromic_partitioning".} =
  if v.isNil or n < 2 or n > 65 or v[0] < 1 or v[0] > 64 or n != csize_t(v[0] + 1): return -1
  let m = int(v[0]); var p: array[64, array[64, bool]]; var cuts: array[64, int64]
  for ending in 0..<m:
    let x = v[ending + 1]; if x < 0 or x > 127: return -1
    for start in 0..ending: p[start][ending] = v[start + 1] == x and (ending - start < 2 or p[start + 1][ending - 1])
  for ending in 0..<m:
    if p[0][ending]: cuts[ending] = 0
    else:
      cuts[ending] = 64
      for start in 1..ending:
        if p[start][ending] and cuts[start - 1] + 1 < cuts[ending]: cuts[ending] = cuts[start - 1] + 1
  cuts[m - 1]
