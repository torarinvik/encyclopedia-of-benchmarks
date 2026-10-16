proc problem28*(size: int64): int64 {.cdecl, exportc: "problem28".} =
  if size < 0 or size > 100_000: return -1
  var total = 1'i64
  let layerCount = (size + 1) div 2
  for layer in 1'i64 ..< layerCount:
    let oddCorner = 2 * layer + 1
    let evenCorner = 2 * layer
    total += 4 * oddCorner * oddCorner - 6 * evenCorner
  total
