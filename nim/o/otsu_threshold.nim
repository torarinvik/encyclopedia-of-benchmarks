proc otsu_threshold*(v: ptr UncheckedArray[int64], n: csize_t, outp: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "otsu_threshold".} =
  if v == nil or n < 2 or v[0] < 1 or v[0] > 32 or n != csize_t(v[0] + 1): return -1
  let count = int(v[0])
  var hist: array[256, int]
  for j in 0 ..< count:
    let p = v[j+1]
    if p < 0 or p > 255: return -1
    inc hist[int(p)]
  var total = 0.0
  for i in 0 ..< 256: total += float(i * hist[i])
  var maxv = 0.0
  var sum = 0.0
  var wb = 0
  var threshold = 0
  for i in 0 ..< 256:
    wb += hist[i]
    if wb == 0: continue
    let wf = count - wb
    if wf == 0: break
    sum += float(i * hist[i])
    let mb = sum / float(wb)
    let mf = (total - sum) / float(wf)
    let variance = float(wb * wf) * (mb - mf) * (mb - mf)
    if variance > maxv: maxv = variance; threshold = i
  if cap < csize_t(count) or outp == nil: return -2
  for j in 0 ..< count: outp[j] = (if v[j+1] > int64(threshold): 255'u8 else: 0'u8)
  int64(count)
