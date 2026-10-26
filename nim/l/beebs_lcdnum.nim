## Clean-room bounded digit-to-segment profile for the BEEBS lcdnum source.
const
  InputBytes = 5
  SegmentMasks: array[16, uint8] = [0x00'u8,0x24'u8,0x5D'u8,0x6D'u8,
    0x2E'u8,0x5D'u8,0x7B'u8,0x25'u8,0x7F'u8,0x6F'u8,0x3F'u8,0x7A'u8,
    0x53'u8,0x7C'u8,0x5B'u8,0x1B'u8]

proc beebs_lcdnum*(values: ptr UncheckedArray[int64], length: csize_t,
                   output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "beebs_lcdnum".} =
  if values.isNil or length != InputBytes: return -1
  for i in 0 ..< InputBytes:
    if values[i] < 0 or values[i] > 255: return -1
  if output.isNil or capacity < InputBytes: return -2
  for i in 0 ..< InputBytes:
    output[i] = SegmentMasks[int(values[i] and 0x0F)]
  InputBytes.int64
