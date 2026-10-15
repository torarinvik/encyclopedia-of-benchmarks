proc alaw_encode*(input: int64): int64 {.cdecl, exportc: "alaw_encode".} =
  if input < -32768 or input > 32767: return -1
  let sample = int32(input)
  let sign = if sample < 0: 0x80'i32 else: 0'i32
  let magnitude = if sample < 0: -sample - 1 else: sample
  var segment = 7'i32
  var mask = 0x4000'i32
  while (magnitude and mask) == 0 and segment > 0:
    dec segment
    mask = mask shr 1
  let shift = if segment != 0: segment + 3 else: 4
  let quantization = (magnitude shr shift) and 0x0f
  int64((sign or (segment shl 4) or quantization) xor 0xD5'i32)
