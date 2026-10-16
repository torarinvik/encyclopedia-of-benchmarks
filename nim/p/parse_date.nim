proc parse_date*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "parse_date".} =
  if v.isNil or n < 9 or n > 11 or v[0] < 8 or v[0] > 10 or n != csize_t(v[0] + 1): return -1
  let length = int(v[0]); var slash1 = 0; var slash2 = 0
  for i in 1..length:
    if v[i] < 0 or v[i] > 127: return -1
    if v[i] == 47:
      if slash1 == 0: slash1 = i
      elif slash2 == 0: slash2 = i
      else: return -1
  if slash1 < 2 or slash1 > 3 or slash2 <= slash1+1 or slash2-slash1 < 2 or slash2-slash1 > 3 or length-slash2 != 4: return -1
  var d=0'i64; var m=0'i64; var y=0'i64
  for i in 1..<slash1:
    if v[i] < 48 or v[i] > 57: return -1
    d=d*10+v[i]-48
  for i in slash1+1..<slash2:
    if v[i] < 48 or v[i] > 57: return -1
    m=m*10+v[i]-48
  for i in slash2+1..length:
    if v[i] < 48 or v[i] > 57: return -1
    y=y*10+v[i]-48
  if m < 1 or m > 12: return -1
  var days = [31'i64,28,31,30,31,30,31,31,30,31,30,31]
  if m == 2 and y mod 4 == 0 and (y mod 100 != 0 or y mod 400 == 0): days[1]=29
  if d < 1 or d > days[int(m-1)]: return -1
  y*10000+m*100+d

