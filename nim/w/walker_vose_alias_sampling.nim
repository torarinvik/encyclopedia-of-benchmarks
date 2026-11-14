proc walker_vose_alias_sampling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "walker_vose_alias_sampling".} =
  if input.isNil or length < 3 or length > 83: return -1
  let nr = input[0]
  let qr = input[1]
  if nr < 1 or nr > 16 or qr < 0 or qr > 32: return -1
  let n = int(nr)
  let q = int(qr)
  if length != csize_t(2 + n + 2 * q): return -1
  var total = 0'i64
  for i in 0 ..< n:
    if input[2+i] < 0 or input[2+i] > 100: return -1
    total += input[2+i]
  if total == 0: return -1
  for i in 0 ..< q:
    let col = input[2+n+2*i]
    let ticket = input[3+n+2*i]
    if col < 0 or col >= nr or ticket < 0 or ticket >= total: return -1
  if q == 0: return 0
  if output.isNil or capacity < csize_t(8*q): return -2
  var mass, threshold: array[16, int64]
  var alias: array[16, int]
  var small, large: seq[int]
  for i in 0 ..< n:
    mass[i] = nr * input[2+i]
    threshold[i] = total
    alias[i] = i
    if mass[i] < total: small.add(i) else: large.add(i)
  while small.len > 0 and large.len > 0:
    let low = small.pop()
    let high = large.pop()
    threshold[low] = mass[low]
    alias[low] = high
    mass[high] -= total - mass[low]
    if mass[high] < total: small.add(high) else: large.add(high)
  var staged: array[256, uint8]
  for i in 0 ..< q:
    let col = int(input[2+n+2*i])
    let ticket = input[3+n+2*i]
    let selected = if ticket < threshold[col]: col else: alias[col]
    let bits = uint64(selected)
    for b in 0 ..< 8: staged[8*i+b] = uint8((bits shr (8*b)) and 255)
  for i in 0 ..< 8*q: output[i] = staged[i]
  int64(8*q)
