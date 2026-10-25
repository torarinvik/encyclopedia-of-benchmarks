const InputBytes = 139
const OutputBytes = 64
const IdctQ16 = [11363'i64, 9633, 6436, 2260, -2260, -6436, -9633, -11363]

proc floorQ16(value: int64): int64 =
  if value >= 0: return value div 65536
  -((-value + 65535) div 65536)

proc validJpegBlock(v: ptr UncheckedArray[int64]): bool =
  if v[0] != 255 or v[1] != 216 or v[2] != 255 or v[3] != 219 or v[4] != 0 or v[5] != 67 or v[6] != 0: return false
  for i in 0 ..< 64:
    if v[7+i] < 1 or v[7+i] > 255 or (i >= 2 and v[7+i] != 1): return false
  let sof = [255'i64, 192, 0, 11, 8, 0, 8, 0, 8, 1, 1, 17, 0]
  for i in 0 ..< sof.len:
    if v[71+i] != sof[i]: return false
  if v[84] != 255 or v[85] != 196 or v[86] != 0 or v[87] != 39 or v[88] != 0 or v[89] != 1 or v[90] != 0 or v[105] != 4 or v[106] != 16 or v[107] != 1 or v[108] != 1 or v[123] != 4 or v[124] != 0: return false
  for i in 91 ..< 105:
    if v[i] != 0: return false
  for i in 109 ..< 123:
    if v[i] != 0: return false
  let sos = [255'i64, 218, 0, 8, 1, 1, 0, 0, 63, 0]
  for i in 0 ..< sos.len:
    if v[125+i] != sos[i]: return false
  v[137] == 255 and v[138] == 217

proc picojpeg*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "picojpeg".} =
  if values.isNil or length != csize_t(InputBytes): return -1
  for i in 0 ..< InputBytes:
    if values[i] < 0 or values[i] > 255: return -1
  if not validJpegBlock(values): return -1
  let scan = (values[135] shl 8) or values[136]
  if (scan and 0x8000) != 0 or (scan and 0x0400) != 0 or ((scan shr 4) and 3) != 2 or (scan and 15) != 15: return -1
  let dcRaw = (scan shr 11) and 15
  let acRaw = (scan shr 6) and 15
  let dc = (if dcRaw >= 8: dcRaw else: dcRaw - 15) * values[7]
  let ac = (if acRaw >= 8: acRaw else: acRaw - 15) * values[8]
  if output.isNil or capacity < csize_t(OutputBytes): return -2
  for y in 0 ..< 8:
    for x in 0 ..< 8:
      let numerator = 128'i64 * 65536 + dc * 8192 + ac * IdctQ16[x] + 32768
      let pixel = max(0'i64, min(255'i64, floorQ16(numerator)))
      output[y*8+x] = uint8(pixel)
  OutputBytes.int64
