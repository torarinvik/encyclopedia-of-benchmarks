const MaxN = 16
const InvalidResult = -1'i64

proc minimum_area_rectangle_arbitrary_orientation*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_area_rectangle_arbitrary_orientation".} =
  if input == nil or length < csize_t(1) or length > csize_t(34): return InvalidResult
  let nValue = input[0]
  if nValue < 4'i64 or nValue > int64(MaxN): return InvalidResult
  let n = int(nValue)
  if length != csize_t(1 + 2 * n): return InvalidResult

  var xs: array[MaxN, int64]
  var ys: array[MaxN, int64]
  for i in 0 ..< n:
    xs[i] = input[1 + 2 * i]
    ys[i] = input[2 + 2 * i]
    if xs[i] < -32 or xs[i] > 32 or ys[i] < -32 or ys[i] > 32:
      return InvalidResult
    for j in 0 ..< i:
      if xs[i] == xs[j] and ys[i] == ys[j]: return InvalidResult

  var best = -1'i64
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let dx1 = xs[i] - xs[j]
      let dy1 = ys[i] - ys[j]
      let midX = xs[i] + xs[j]
      let midY = ys[i] + ys[j]
      let len1 = dx1 * dx1 + dy1 * dy1
      for k in 0 ..< n:
        for l in k + 1 ..< n:
          if k < i or (k == i and l <= j): continue
          if k == i or k == j or l == i or l == j: continue
          if midX != xs[k] + xs[l] or midY != ys[k] + ys[l]: continue
          let dx2 = xs[k] - xs[l]
          let dy2 = ys[k] - ys[l]
          if len1 != dx2 * dx2 + dy2 * dy2: continue
          let area2 = abs(dx1 * dy2 - dy1 * dx2)
          if best < 0 or area2 < best: best = area2
  if best < 0: 0 else: best
