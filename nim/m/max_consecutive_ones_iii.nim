proc max_consecutive_ones_iii*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "max_consecutive_ones_iii".} =
  if a.isNil or length < 3 or length > 1026 or a[0] < 1 or a[0] > 1024 or length != csize_t(a[0] + 2) or a[1] < 0 or a[1] > a[0]: return -2
  let n=int(a[0]); for i in 0 ..< n: if a[i+2] != 0 and a[i+2] != 1: return -2
  var left=0; var zeros=0; var best=0
  for right in 0 ..< n:
    if a[right+2] == 0: inc zeros
    while zeros > int(a[1]):
      if a[left+2] == 0: dec zeros
      inc left
    best=max(best,right-left+1)
  int64(best)
