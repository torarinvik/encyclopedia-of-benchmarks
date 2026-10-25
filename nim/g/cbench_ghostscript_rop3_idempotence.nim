## Independent bounded profile; complete Aladdin Free Public License v5 is bundled.
proc cbench_ghostscript_rop3_idempotence*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "cbench_ghostscript_rop3_idempotence".} =
  if length > 2 or (length != 0 and values == nil): return -1
  if length != 1: return -1
  if values[0] < 0 or values[0] > 255: return -1
  let code = uint64(values[0])
  for bit in countup(1, 7, 2):
    if ((code shr bit) and 1'u64) != 0 and ((code shr (bit - 1)) and 1'u64) == 0: return 0
  1
