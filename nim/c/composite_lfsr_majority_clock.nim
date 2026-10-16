## One majority-clock step for the three source-configured A5 LFSRs.
proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc composite_lfsr_majority_clock*(input: ptr UncheckedArray[int64], length: csize_t,
                                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "composite_lfsr_majority_clock".} =
  if input.isNil or length != 3: return -1
  if input[0] < 0 or input[0] > 524287 or input[1] < 0 or input[1] > 4194303 or input[2] < 0 or input[2] > 8388607: return -1
  if output.isNil or outputCapacity < 32: return -2
  var s1 = uint64(input[0]); var s2 = uint64(input[1]); var s3 = uint64(input[2])
  let c1 = (s1 shr 8) and 1'u64; let c2 = (s2 shr 10) and 1'u64; let c3 = (s3 shr 10) and 1'u64
  let majority = c1 + c2 + c3 >= 2
  let emitted = ((s1 shr 18) xor (s2 shr 21) xor (s3 shr 22)) and 1'u64
  if (c1 == 1) == majority: s1 = ((s1 shl 1) and 524287'u64) or (((s1 shr 13) xor (s1 shr 16) xor (s1 shr 17) xor (s1 shr 18)) and 1'u64)
  if (c2 == 1) == majority: s2 = ((s2 shl 1) and 4194303'u64) or (((s2 shr 20) xor (s2 shr 21)) and 1'u64)
  if (c3 == 1) == majority: s3 = ((s3 shl 1) and 8388607'u64) or (((s3 shr 7) xor (s3 shr 20) xor (s3 shr 21) xor (s3 shr 22)) and 1'u64)
  writeI64Le(output, 0, int64(emitted)); writeI64Le(output, 8, int64(s1))
  writeI64Le(output, 16, int64(s2)); writeI64Le(output, 24, int64(s3))
  32
