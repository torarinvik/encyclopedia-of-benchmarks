proc putI64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[at * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc zdd_family_count*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "zdd_family_count".} =
  if input.isNil or length < 2 or length > 34: return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > 6 or m0 < 0 or m0 > 32 or int(length) != int(m0) + 2: return -1
  let n = int(n0); let limit = 1 shl n; let m = int(m0)
  var ids, next: array[64, int64]
  var vars, lows, highs: array[63, int64]
  var counts: array[65, int64]
  var seen: array[64, bool]
  counts[1] = 1
  for i in 0..<m:
    let mask = input[2 + i]
    if mask < 0 or mask >= int64(limit) or seen[int(mask)]: return -1
    seen[int(mask)] = true; ids[int(mask)] = 1
  var nodes = 0; var currentCount = limit
  for variable in 0..<n:
    let nextCount = currentCount div 2
    for p in 0..<nextCount:
      let low = ids[2*p]; let high = ids[2*p+1]
      if high == 0:
        next[p] = low
        continue
      var found = nodes; var j = nodes
      while j > 0:
        dec j
        if int(vars[j]) != variable: break
        if lows[j] == low and highs[j] == high:
          found = j
          break
      if found == nodes:
        vars[nodes] = int64(variable); lows[nodes] = low; highs[nodes] = high
        counts[2+nodes] = counts[int(low)] + counts[int(high)]
        next[p] = int64(2+nodes); inc nodes
      else: next[p] = int64(2+found)
    for p in 0..<nextCount: ids[p] = next[p]
    currentCount = nextCount
  let bytes = 8 * (3 + 3 * nodes)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output, 0, ids[0]); putI64(output, 1, int64(nodes)); putI64(output, 2, counts[int(ids[0])])
  for i in 0..<nodes:
    putI64(output, 3+3*i, vars[i]); putI64(output, 4+3*i, lows[i]); putI64(output, 5+3*i, highs[i])
  int64(bytes)
