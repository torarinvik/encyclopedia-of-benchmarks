proc putI64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[at * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc binary_decision_graph*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "binary_decision_graph".} =
  if input.isNil or length < 2 or length > 65: return -1
  let nv = input[0]
  if nv < 1 or nv > 6 or int(length) != 1 + (1 shl int(nv)): return -1
  let n = int(nv)
  let count = 1 shl n
  var ids, next: array[64, int64]
  var vars, lows, highs: array[63, int64]
  for i in 0..<count:
    if input[i + 1] != 0 and input[i + 1] != 1: return -1
    ids[i] = input[i + 1]
  var nodes = 0
  var currentCount = count
  for step in 0..<n:
    let variable = n - 1 - step
    let nextCount = currentCount div 2
    for p in 0..<nextCount:
      let lo = ids[2 * p]
      let hi = ids[2 * p + 1]
      if lo == hi:
        next[p] = lo
        continue
      var found = nodes
      var j = nodes
      while j > 0:
        dec j
        if int(vars[j]) != variable: break
        if lows[j] == lo and highs[j] == hi:
          found = j
          break
      if found == nodes:
        vars[nodes] = int64(variable); lows[nodes] = lo; highs[nodes] = hi
        next[p] = int64(2 + nodes); inc nodes
      else: next[p] = int64(2 + found)
    for p in 0..<nextCount: ids[p] = next[p]
    currentCount = nextCount
  let bytes = 8 * (2 + 3 * nodes)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output, 0, ids[0]); putI64(output, 1, int64(nodes))
  for i in 0..<nodes:
    putI64(output, 2 + 3 * i, vars[i]); putI64(output, 3 + 3 * i, lows[i]); putI64(output, 4 + 3 * i, highs[i])
  int64(bytes)
