## Clean-room port of SIM's documented first-best local affine score.
const Stride = 65
const MaxLength = 64

proc ptrdist_sim_local_affine_alignment*(input: ptr int64, length: csize_t): int64 {.cdecl, exportc: "ptrdist_sim_local_affine_alignment".} =
  if input == nil or length < 4 or length > 130: return -1
  let x = cast[ptr UncheckedArray[int64]](input)
  if x[0] < 1 or x[0] > MaxLength: return -1
  let left = int(x[0])
  let rightPos = 1 + left
  if csize_t(rightPos) >= length or x[rightPos] < 1 or x[rightPos] > MaxLength: return -1
  let right = int(x[rightPos])
  if int(length) != rightPos + 1 + right: return -1
  for i in 0 ..< left:
    if x[1+i] notin [65'i64, 67'i64, 71'i64, 84'i64]: return -1
  for j in 0 ..< right:
    if x[rightPos+1+j] notin [65'i64, 67'i64, 71'i64, 84'i64]: return -1
  var h: array[Stride * Stride, int64]
  var d: array[Stride * Stride, int64]
  var f: array[Stride * Stride, int64]
  for j in 1 .. right: d[j] = -60
  for i in 1 .. left: f[i*Stride] = -60
  var best: int64 = 0
  for i in 1 .. left:
    for j in 1 .. right:
      let p = i*Stride+j
      d[p] = max(h[p-Stride]-62, d[p-Stride]-2)
      f[p] = max(h[p-1]-62, f[p-1]-2)
      var score = h[p-Stride-1] + (if x[i] == x[rightPos+j]: 10'i64 else: -10'i64)
      score = max(0'i64, max(score, max(d[p], f[p])))
      h[p] = score
      best = max(best, score)
  best
