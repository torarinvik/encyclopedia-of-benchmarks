proc x932_padding*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "x932_padding".} =
  if values == nil or length < 1 or length > 257: return -1
  if values[0] < 1 or values[0] > 64: return -1
  let block = int(values[0])
  let n = int(length) - 1
  for i in 1 ..< int(length):
    if values[i] < 0 or values[i] > 255: return -1
  let pad = block - (n mod block)
  let total = n + pad
  if total > int(capacity) or output == nil: return -2
  for i in 0 ..< n: output[i] = uint8(values[i + 1])
  for i in n ..< total - 1: output[i] = 0
  output[total - 1] = uint8(pad)
  int64(total)
