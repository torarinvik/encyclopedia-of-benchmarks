## Emit the pinned minimal-width two's-complement string for a signed integer.
proc twos_complement*(value: int64, output: ptr UncheckedArray[uint8], output_capacity: csize_t): int64
    {.cdecl, exportc: "twos_complement".} =
  if value > 0: return -1
  if value == 0:
    if output == nil or output_capacity < 3: return -2
    output[0] = uint8(ord('0')); output[1] = uint8(ord('b')); output[2] = uint8(ord('0'))
    return 3
  let magnitude = uint64(-(value + 1)) + 1'u64
  var bit_length = 0
  var remaining = magnitude
  while remaining > 0:
    inc bit_length
    remaining = remaining shr 1
  let suffix = if bit_length == 64: magnitude else: (1'u64 shl bit_length) - magnitude
  var bits: array[64, uint8]
  var bit_count = 0
  remaining = suffix
  while remaining > 0:
    bits[bit_count] = uint8(ord('0')) + uint8(remaining and 1)
    inc bit_count
    remaining = remaining shr 1
  let required = bit_length + 3
  if output == nil or output_capacity < csize_t(required): return -2
  var position = 0
  output[position] = uint8(ord('0')); inc position
  output[position] = uint8(ord('b')); inc position
  output[position] = uint8(ord('1')); inc position
  for _ in bit_count ..< bit_length:
    output[position] = uint8(ord('0')); inc position
  while bit_count > 0:
    dec bit_count
    output[position] = bits[bit_count]
    inc position
  int64(position)
