proc putF64Le(output: ptr UncheckedArray[uint8], offset: var int, value: float64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    output[offset] = uint8((bits shr (8 * b)) and 0xFF'u64)
    inc offset
proc putI64Le(output: ptr UncheckedArray[uint8], offset: var int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    output[offset] = uint8((bits shr (8 * b)) and 0xFF'u64)
    inc offset

proc correlation_matrix_analysis*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "correlation_matrix_analysis".} =
  if input.isNil or length < 2 or length > 22: return -1
  if input[0] != 4 or input[1] < 2 or input[1] > 5: return -1
  let p = int(input[1])
  if length != csize_t(2 + 4 * p): return -1
  for i in 0 ..< 4 * p:
    if input[2 + i] < -1000 or input[2 + i] > 1000: return -1
  for col in 0 ..< p:
    var varying = false
    for row in 1 ..< 4:
      if input[2 + row * p + col] != input[2 + col]: varying = true
    if not varying: return -1
  let outputBytes = 32 * p * p + 48
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var means: array[5, float64]
  for col in 0 ..< p:
    for row in 0 ..< 4: means[col] += float64(input[2 + row * p + col])
    means[col] /= 4.0
  var corr, raw, bonf, fdr: array[25, float64]
  for i in 0 ..< 25: raw[i] = 1.0; bonf[i] = 1.0; fdr[i] = 1.0
  for i in 0 ..< p: corr[i * p + i] = 1.0
  var pairI, pairJ: array[10, int]
  var pairP: array[10, float64]
  var count = 0
  for j in 1 ..< p:
    for i in 0 ..< j:
      var cross, sumI, sumJ = 0.0
      for row in 0 ..< 4:
        let dx = float64(input[2 + row * p + i]) - means[i]
        let dy = float64(input[2 + row * p + j]) - means[j]
        cross += dx * dy; sumI += dx * dx; sumJ += dy * dy
      let r = cross / sqrt(sumI * sumJ)
      let pv = 1.0 - abs(r)
      corr[i * p + j] = r; corr[j * p + i] = r
      raw[i * p + j] = pv; raw[j * p + i] = pv
      pairI[count] = i; pairJ[count] = j; pairP[count] = pv; inc count
  var order: array[10, int]
  for k in 0 ..< count:
    let adj = min(1.0, pairP[k] * float64(count))
    bonf[pairI[k] * p + pairJ[k]] = adj; bonf[pairJ[k] * p + pairI[k]] = adj
    order[k] = k
  for k in 1 ..< count:
    let value = order[k]
    var at = k
    while at > 0 and pairP[order[at - 1]] > pairP[value]: order[at] = order[at - 1]; dec at
    order[at] = value
  var running = 1.0
  for pos in countdown(count - 1, 0):
    let adj = min(1.0, pairP[order[pos]] * float64(count) / float64(pos + 1))
    running = min(running, adj)
    let k = order[pos]; let a = pairI[k] * p + pairJ[k]; let b = pairJ[k] * p + pairI[k]
    fdr[a] = running; fdr[b] = running
  var sigRaw, sigBonf, sigFdr = 0'i64
  for k in 0 ..< count:
    let index = pairI[k] * p + pairJ[k]
    if pairP[k] < 0.05: inc sigRaw
    if bonf[index] < 0.05: inc sigBonf
    if fdr[index] < 0.05: inc sigFdr
  var offset = 0
  for i in 0 ..< p * p: putF64Le(output, offset, corr[i])
  for i in 0 ..< p * p: putF64Le(output, offset, raw[i])
  for i in 0 ..< p * p: putF64Le(output, offset, bonf[i])
  for i in 0 ..< p * p: putF64Le(output, offset, fdr[i])
  for value in [4'i64, int64(p), 0'i64, sigRaw, sigBonf, sigFdr]: putI64Le(output, offset, value)
  int64(offset)
