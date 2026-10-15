proc alaw_decode*(input: int64): int64 {.cdecl, exportc: "alaw_decode".} =
  if input < 0 or input > 255: return -1
  let alaw = int32(input) xor 0xD5'i32
  let sign = alaw and 0x80'i32
  let segment = (alaw and 0x70'i32) shr 4
  var sample = ((alaw and 0x0f'i32) shl 4) or 8'i32
  if segment != 0: sample += 0x100
  let shift = if segment > 1: segment - 1 else: 0
  sample = sample shl shift
  if sign != 0: return int64(-sample)
  int64(sample)
