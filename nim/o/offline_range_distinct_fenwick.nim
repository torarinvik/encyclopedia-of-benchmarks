proc add(tree: var array[65, int64], n, position: int, delta: int64) =
  var i = position + 1
  while i <= n:
    tree[i] += delta
    i += i and -i

proc prefix(tree: array[65, int64], finish: int): int64 =
  var i = finish
  while i > 0:
    result += tree[i]
    i = i and (i - 1)

proc offline_range_distinct_fenwick*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "offline_range_distinct_fenwick".} =
  if input.isNil or length < 3 or length > 195: return -1
  let nr = input[0]
  let qr = input[1]
  if nr < 1 or nr > 64 or qr < 0 or qr > 64: return -1
  let n = int(nr)
  let q = int(qr)
  if length != csize_t(2+n+2*q): return -1
  for i in 0 ..< n:
    if input[2+i] < 0 or input[2+i] > 255: return -1
  var head: array[65, int]
  var next: array[64, int]
  var last: array[256, int]
  var tree: array[65, int64]
  for i in 0 ..< 65: head[i] = -1
  for i in 0 ..< 256: last[i] = -1
  for i in 0 ..< q:
    let left = input[2+n+2*i]
    let right = input[3+n+2*i]
    if left < 0 or left > right or right > nr: return -1
    next[i] = head[int(right)]
    head[int(right)] = i
  var answer = 0'i64
  for right in 0 .. n:
    if right > 0:
      let value = int(input[1+right])
      if last[value] >= 0: add(tree, n, last[value], -1)
      add(tree, n, right-1, 1)
      last[value] = right-1
    var query = head[right]
    while query >= 0:
      let left = int(input[2+n+2*query])
      answer += int64(query+1) * (prefix(tree, right)-prefix(tree, left))
      query = next[query]
  answer
