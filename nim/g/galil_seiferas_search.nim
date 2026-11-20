type
  I64Input = ptr UncheckedArray[int64]

proc galil_seiferas_search*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "galil_seiferas_search".} =
  if values.isNil or length < 2 or length > 162: return -2
  if values[0] < 0 or values[0] > 128 or values[1] < 1 or values[1] > 32: return -2
  let n = int(values[0])
  let m = int(values[1])
  if length != csize_t(2 + n + m): return -2
  for i in 0 ..< n + m:
    if values[2 + i] < 0 or values[2 + i] > 15: return -2
  if m > n: return 0
  let p0 = 2 + n
  var s = 0
  var p1 = 1
  var q1 = 0
  var factorized = false
  while true:
    while s + p1 + q1 < m and values[p0 + s + q1] == values[p0 + s + p1 + q1]: inc q1
    if p1 + q1 >= 4 * p1:
      var p2 = q1
      var q2 = 0
      while true:
        while p2 + q2 < 4 * p2 and s + p2 + q2 < m and values[p0 + s + q2] == values[p0 + s + p2 + q2]: inc q2
        if p2 + q2 == 4 * p2:
          while true:
            while s + p1 + q1 < m and values[p0 + s + q1] == values[p0 + s + p1 + q1]: inc q1
            while p1 + q1 >= 4 * p1:
              s += p1
              q1 -= p1
            if s + p1 + q1 == m: break
            p1 += q1 div 4 + 1
            q1 = 0
            if p1 >= p2: break
          break
        if s + p2 + q2 == m:
          factorized = true
          break
        if q2 == p1 + q1:
          p2 += p1
          q2 -= p1
        else:
          p2 += q2 div 4 + 1
          q2 = 0
      if factorized or s + p1 + q1 == m: break
    else:
      if s + p1 + q1 == m: break
      p1 += q1 div 4 + 1
      q1 = 0

  var p = 0
  var q = 0
  var matches = 0'i64
  while p <= n - m:
    while s + q < m and values[p0 + s + q] == values[2 + p + s + q]: inc q
    if q == m - s:
      var i = 0
      while i < s and values[p0 + i] == values[2 + p + i]: inc i
      if i == s: inc matches
    if q == p1 + q1:
      p += p1
      q -= p1
    else:
      p += q div 4 + 1
      q = 0
  matches
