proc optimal_file_merging*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "optimal_file_merging".} =
  if values == nil or length < 1 or length > 33: return -1
  let count = values[0]
  if count < 0 or count > 32 or length != csize_t(count) + 1: return -1
  var files: array[32, int64]
  for i in 0 ..< int(count):
    if values[i + 1] < 0 or values[i + 1] > 1_000_000: return -1
    files[i] = values[i + 1]
  var n = int(count)
  var total = 0'i64
  while n > 1:
    var a = 0
    var b = 1
    if files[b] < files[a]: swap(a, b)
    for i in 2 ..< n:
      if files[i] < files[a]:
        b = a
        a = i
      elif files[i] < files[b]:
        b = i
    let merged = files[a] + files[b]
    total += merged
    if a > b: swap(a, b)
    files[a] = merged
    files[b] = files[n - 1]
    dec n
  return total
