## Uncompiled minimum tree path-partition draft.
proc tree_minimum_path_partition*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_minimum_path_partition".} =
  if input == nil or length < 1 or length > 65: return -1
  let nv = input[0]
  if nv < 1 or nv > 64 or length != csize_t(nv): return -1
  let n = int(nv)
  for v in 1 ..< n:
    if input[v] < 0 or input[v] >= int64(v): return -1
  var base, first, second: array[64, int64]
  var v = n-1
  while v > 0:
    let p = int(input[v])
    let best = base[v] + first[v] + second[v]
    let gain = 1 + base[v] + first[v] - best
    base[p] += best
    if gain > first[p]:
      second[p] = first[p]
      first[p] = gain
    elif gain > second[p]: second[p] = gain
    dec v
  nv - base[0] - first[0] - second[0]
