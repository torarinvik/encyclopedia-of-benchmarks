const
  OutputBytes = 12
  U32Max = 4_294_967_295'i64

proc reverseBits32(value: uint32): uint32 =
  var n = value
  n = ((n shr 1) and 0x55555555'u32) or ((n and 0x55555555'u32) shl 1)
  n = ((n shr 2) and 0x33333333'u32) or ((n and 0x33333333'u32) shl 2)
  n = ((n shr 4) and 0x0f0f0f0f'u32) or ((n and 0x0f0f0f0f'u32) shl 4)
  ((n and 0xff000000'u32) shr 24) or ((n and 0x00ff0000'u32) shr 8) or
    ((n and 0x0000ff00'u32) shl 8) or ((n and 0x000000ff'u32) shl 24)

proc reverseBits64(value: uint64): uint64 =
  var n = value
  n = ((n shr 1) and 0x5555555555555555'u64) or ((n and 0x5555555555555555'u64) shl 1)
  n = ((n shr 2) and 0x3333333333333333'u64) or ((n and 0x3333333333333333'u64) shl 2)
  n = ((n shr 4) and 0x0f0f0f0f0f0f0f0f'u64) or ((n and 0x0f0f0f0f0f0f0f0f'u64) shl 4)
  ((n and 0xff00000000000000'u64) shr 56) or ((n and 0x00ff000000000000'u64) shr 40) or
    ((n and 0x0000ff0000000000'u64) shr 24) or ((n and 0x000000ff00000000'u64) shr 8) or
    ((n and 0x00000000ff000000'u64) shl 8) or ((n and 0x0000000000ff0000'u64) shl 24) or
    ((n and 0x000000000000ff00'u64) shl 40) or ((n and 0x00000000000000ff'u64) shl 56)

proc revert_bits*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "revert_bits".} =
  if input.isNil or length != csize_t(2) or input[0] < 0 or input[0] > U32Max: return -1
  if output.isNil or capacity < csize_t(OutputBytes): return -2
  let reversed32 = reverseBits32(uint32(input[0]))
  let reversed64 = reverseBits64(cast[uint64](input[1]))
  for i in 0 ..< 4: output[i] = uint8(reversed32 shr (8 * i))
  for i in 0 ..< 8: output[4 + i] = uint8(reversed64 shr (8 * i))
  OutputBytes
