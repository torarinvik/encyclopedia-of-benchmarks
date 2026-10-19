## Bounded port of the Benchmark Game fannkuch counter traversal.
proc fannkuch*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "fannkuch".} =
  if values == nil or length != 1: return -1
  let n64 = values[0]
  if n64 < 1 or n64 > 8: return -1
  let n = int(n64)
  var perm, perm1, count: array[8, int]
  for i in 0..<n: perm1[i] = i
  var r = n
  var flipsMax = 0
  while true:
    while r != 1:
      count[r - 1] = r
      dec r
    if perm1[0] != 0 and perm1[n - 1] != n - 1:
      for i in 1..<n: perm[i] = perm1[i]
      var k = perm1[0]
      var flips = 0
      while true:
        var i = 1
        var j = k - 1
        while i < j:
          swap(perm[i], perm[j])
          inc i
          dec j
        inc flips
        j = perm[k]
        perm[k] = k
        k = j
        if k == 0: break
      if flipsMax < flips: flipsMax = flips
    while true:
      if r == n: return int64(flipsMax)
      let first = perm1[0]
      for i in 0..<r: perm1[i] = perm1[i + 1]
      perm1[r] = first
      dec count[r]
      if count[r] > 0: break
      inc r
