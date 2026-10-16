proc ngram*(v: ptr UncheckedArray[int64], n: csize_t, out: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "ngram".} =
  if v.isNil or n < 2 or n > 258 or v[0] < 1 or v[0] > 16 or v[1] < 0 or v[1] > 256 or n != csize_t(v[1]) + 2: return -1
  let width = int(v[0]); let text = int(v[1])
  for i in 0 ..< text:
    if v[i + 2] < 32 or v[i + 2] > 126: return -1
  let grams = if text >= width: text - width + 1 else: 0
  let bytes = if grams > 0: grams * width + grams - 1 else: 0
  if bytes > int(cap) or (bytes > 0 and out.isNil): return -2
  var w = 0
  for i in 0 ..< grams:
    if i > 0: out[w] = 10'u8; inc w
    for j in 0 ..< width: out[w] = uint8(v[i + j + 2]); inc w
  int64(w)
