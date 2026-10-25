## Independent ROP3 truth-table transforms; complete AFPL v5 is bundled.
proc cbench_ghostscript_rop3_transform*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "cbench_ghostscript_rop3_transform".} =
  if length > 3 or (length != 0 and values == nil): return -1
  if length != 2 or values[0] < 0 or values[0] > 14 or values[1] < 0 or values[1] > 255: return -1
  let mode = int(values[0]); let code = uint64(values[1])
  var result = 0'u64
  for index in 0 ..< 8:
    let d = index and 1; let s = (index shr 1) and 1; let t = (index shr 2) and 1
    var sourceIndex = index
    var forced = -1
    if mode <= 2: sourceIndex = sourceIndex xor (1 shl mode)
    elif mode <= 8:
      let dimension = (mode - 3) div 2; let pinned = (mode - 3) and 1
      sourceIndex = (index and not (1 shl dimension)) or (pinned shl dimension)
    elif mode == 9: sourceIndex = (index and not 6) or (s shl 2) or (t shl 1)
    elif mode <= 13:
      let operand = if mode < 12: s else: t
      if operand == ((mode - 10) and 1): forced = d
    else: forced = 1 - int((code shr index) and 1'u64)
    let bit = if forced < 0: int((code shr sourceIndex) and 1'u64) else: forced
    result = result or (uint64(bit) shl index)
  int64(result)
