proc naive_pattern_search*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "naive_pattern_search".} =
  if v == nil or n < 2 or n > 512: return -2
  let tn=v[0]; let pn=v[1]
  if tn < 0 or tn > 255 or pn < 0 or pn > tn or n != csize_t(2+tn+pn): return -2
  for i in 0..<int(tn+pn):
    if v[2+i] < 0 or v[2+i] > 127: return -2
  if pn == 0: return -1
  for start in 0..(tn-pn):
    var j: int64=0
    while j < pn and v[2+int(start+j)] == v[2+int(tn+j)]: inc j
    if j == pn: return start
  return -1
