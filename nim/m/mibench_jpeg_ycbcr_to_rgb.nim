proc arshift16(x: int64): int64 =
  if x >= 0: x div 65536 else: -((-x + 65535) div 65536)
proc clamp8(x: int64): uint8 = uint8(max(0'i64, min(255'i64, x)))

proc mibench_jpeg_ycbcr_to_rgb*(v: ptr UncheckedArray[int64], n: csize_t,
    output: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "mibench_jpeg_ycbcr_to_rgb".} =
  if v == nil or n < 4 or n > 49: return -1
  if v[0] < 1 or v[0] > 16 or n != (1 + 3 * int(v[0])).csize_t: return -1
  for i in 1 ..< int(n):
    if v[i] < 0 or v[i] > 255: return -1
  var staged: array[48, uint8]
  var p = 0
  for i in countup(1, int(n)-1, 3):
    let y=v[i]; let cb=v[i+1]-128; let cr=v[i+2]-128
    staged[p]=clamp8(y+arshift16(91881*cr+32768)); inc p
    staged[p]=clamp8(y+arshift16(-22554*cb+32768-46802*cr)); inc p
    staged[p]=clamp8(y+arshift16(116130*cb+32768)); inc p
  if output == nil or cap < p.csize_t: return -2
  for i in 0 ..< p: output[i]=staged[i]
  int64(p)
