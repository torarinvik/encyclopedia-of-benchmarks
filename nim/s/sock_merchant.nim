proc sock_merchant*(colors: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sock_merchant".} =
  if length > 512: return -1
  var counts: array[4096, uint64]
  var index = 0.csize_t
  while index < length:
    let value = colors[index]
    if value < 0 or value > 4095: return -1
    inc counts[int(value)]
    inc index
  var pairs = 0'u64
  for color in 0 ..< 4096:
    pairs += counts[color] div 2
  return int64(pairs)
