## Evaluate the six pinned full-wave rectifier helper formulas.
const OutputBytes = 48'i64

proc storeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc full_wave_rectifier*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "full_wave_rectifier".} =
  if values == nil or length != 5: return -1
  let rfI = values[0]
  let rsI = values[1]
  let rlI = values[2]
  let vmI = values[3]
  let imI = values[4]
  if rfI < 0 or rfI > 1_000_000 or rsI < 0 or rsI > 1_000_000 or
      rlI < 1 or rlI > 1_000_000 or vmI < -1_000_000 or vmI > 1_000_000 or
      imI < -1_000_000 or imI > 1_000_000: return -1
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2

  let rf = float64(rfI)
  let rs = float64(rsI)
  let rl = float64(rlI)
  let vm = float64(vmI)
  let im = float64(imI)
  storeF64Le(output, 0, vm / (rf + rs + rl))
  storeF64Le(output, 8, 2.0 * im * 0.318)
  storeF64Le(output, 16, 2.0 * 0.318 * vm)
  storeF64Le(output, 24, vm / rl)
  storeF64Le(output, 32, im * 0.707)
  storeF64Le(output, 40, vm * 0.707)
  OutputBytes
