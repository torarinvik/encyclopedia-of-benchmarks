proc solve(v: ptr UncheckedArray[int64], n, i: int, target, half: int64): bool =
  if target == half: return true
  if i >= n or target > half: return false
  solve(v,n,i+1,target+v[i],half) or solve(v,n,i+1,target,half)
proc partition*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "partition".} =
  if v.isNil or n < 1 or n > 17 or v[0] < 0 or v[0] > 16 or n != csize_t(v[0]+1): return -1
  let count = int(v[0]); var sum = 0'i64
  for i in 1..<int(n):
    if v[i] < 0 or v[i] > 1000: return -1
    sum += v[i]
  if sum mod 2 != 0: return 0
  int64(solve(cast[ptr UncheckedArray[int64]](addr v[1]),count,0,0,sum div 2))

