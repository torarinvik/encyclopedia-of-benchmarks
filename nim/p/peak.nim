proc find_peak(a: ptr UncheckedArray[int64], lo, hi: int): int64 =
  let n = hi - lo; let m = n div 2
  let left = a[lo+m-1]; let center = a[lo+m]; let right = a[lo+m+1]
  if center > left and center > right: return center
  if left < right:
    let start = if m == 2: m-1 else: m
    return find_peak(a,lo+start,hi)
  let finish = if m == 2: m+1 else: m
  find_peak(a,lo,lo+finish)
proc peak*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "peak".} =
  if v.isNil or n < 4 or n > 65 or v[0] < 3 or v[0] > 64 or n != csize_t(v[0]+1): return -1
  let length = int(v[0]); var p = 1
  for i in 0..<length:
    if v[i+1] < -1_000_000 or v[i+1] > 1_000_000: return -1
  while p < length-1 and v[p+1] > v[p]: inc p
  if p == 1 or p >= length-1: return -1
  for i in p..<length-1:
    if v[i+2] >= v[i+1]: return -1
  find_peak(cast[ptr UncheckedArray[int64]](addr v[1]),0,length)

