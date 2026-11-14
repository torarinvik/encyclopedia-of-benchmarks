type Point = tuple[x, y: int64]

proc score(points: array[64, Point], n, row, col: int): int64 =
  if col <= row: return int64(col-row)
  if col >= row+n: return -1
  let dx = points[row].x-points[col mod n].x
  let dy = points[row].y-points[col mod n].y
  dx*dx+dy*dy

proc maxima(points: array[64, Point], n: int, rows, columns: seq[int], answer: var array[64, int]) =
  if rows.len == 0: return
  var reduced: seq[int]
  for col in columns:
    while reduced.len > 0 and score(points,n,rows[reduced.len-1],col) > score(points,n,rows[reduced.len-1],reduced[^1]):
      reduced.setLen(reduced.len-1)
    if reduced.len < rows.len: reduced.add(col)
  var odd: seq[int]
  var i = 1
  while i < rows.len:
    odd.add(rows[i]); i += 2
  maxima(points,n,odd,reduced,answer)
  var low = 0
  i = 0
  while i < rows.len:
    var high = reduced.len-1
    if i+1 < rows.len:
      high = low
      while reduced[high] != answer[rows[i+1]]: inc high
    var best = low
    for j in low+1 .. high:
      if score(points,n,rows[i],reduced[j]) > score(points,n,rows[i],reduced[best]): best = j
    answer[rows[i]] = reduced[best]
    low = high; i += 2

proc all_farthest_neighbors_convex*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 7 or length > 129 or input[0] < 3 or input[0] > 64: return -1
  let n = int(input[0])
  if length != csize_t(1+2*n): return -1
  var points: array[64, Point]
  for i in 0 ..< n:
    let x = input[1+2*i]; let y = input[2+2*i]
    if x < -1000000 or x > 1000000 or y < -1000000 or y > 1000000: return -1
    points[i] = (x,y)
  for i in 0 ..< n:
    let a = points[i]; let b = points[(i+1) mod n]; let c = points[(i+2) mod n]
    if (b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x) >= 0: return -1
  if output == nil or capacity < csize_t(8*n): return -2
  var rows, columns: seq[int]
  for i in 0 ..< n: rows.add(i)
  for i in 0 ..< 2*n-1: columns.add(i)
  var answer: array[64,int]
  maxima(points,n,rows,columns,answer)
  for i in 0 ..< n:
    let index = uint64(answer[i] mod n)
    for byte in 0 ..< 8: output[8*i+byte] = uint8((index shr (8*byte)) and 255)
  int64(8*n)
