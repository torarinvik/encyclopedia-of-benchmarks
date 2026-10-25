## Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled.
proc cbench_ghostscript_rop3_operand_usage*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "cbench_ghostscript_rop3_operand_usage".} =
  if length > 2 or (length != 0 and values == nil): return -1
  if length != 1 or values[0] < 0 or values[0] > 255: return -1
  let code = uint64(values[0])
  var usage = 0'u64
  for dimension in 0 ..< 3:
    let toggle = 1'u64 shl dimension
    for index in 0 ..< 8:
      if (uint64(index) and toggle) == 0 and ((code shr index) and 1'u64) != ((code shr (index or int(toggle))) and 1'u64):
        usage = usage or toggle
        break
  int64(usage)
