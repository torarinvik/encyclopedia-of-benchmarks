proc srmRoot(parent: var array[36, int], start: int): int =
  var x = start
  while parent[x] != x:
    parent[x] = parent[parent[x]]
    x = parent[x]
  x

proc statistical_region_merging_table*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "statistical_region_merging_table".} =
  if input.isNil or length < 4 or length > 74: return -1
  if input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6: return -1
  let width = int(input[1])
  let n = int(input[0]) * width
  if length != csize_t(2 + 2*n): return -1
  for i in 0..<n:
    if input[2+i] < 0 or input[2+i] > 65535 or input[2+n+i] < 0 or input[2+n+i] > 255: return -1
  var parent, sizes, minimum: array[36, int]
  var sums: array[36, int64]
  for i in 0..<n:
    parent[i] = i
    sizes[i] = 1
    minimum[i] = i
    sums[i] = input[2+n+i]
  for diff in 0..<256:
    for p in 0..<n:
      var neighbors: array[2, int]
      var count = 0
      if p mod width + 1 < width:
        neighbors[count] = p+1
        inc count
      if p + width < n:
        neighbors[count] = p+width
        inc count
      for k in 0..<count:
        let q = neighbors[k]
        if abs(input[2+n+p] - input[2+n+q]) != int64(diff): continue
        var a = srmRoot(parent, p)
        var b = srmRoot(parent, q)
        if a == b: continue
        let na = int64(sizes[a])
        let nb = int64(sizes[b])
        let delta = sums[a]*nb - sums[b]*na
        let bound = input[1+sizes[a]] + input[1+sizes[b]]
        if delta*delta > bound*na*na*nb*nb: continue
        if sizes[a] < sizes[b]: swap(a, b)
        parent[b] = a
        sizes[a] += sizes[b]
        sums[a] += sums[b]
        minimum[a] = min(minimum[a], minimum[b])
  if output.isNil or capacity < csize_t(n): return -2
  for i in 0..<n: output[i] = uint8(minimum[srmRoot(parent, i)])
  int64(n)
