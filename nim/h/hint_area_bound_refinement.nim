type HintRect = object
  ahi, alo, dx, flh, fll, frh, frl, xl, xr: int64

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8(bits shr (byte * 8))

proc hint_area_bound_refinement*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hint_area_bound_refinement".} =
  if input.isNil or length != 3: return -1
  let xb = input[0]; let yb = input[1]; let requested = input[2]
  if xb < 1 or xb > 8 or yb < 1 or yb > 8 or xb + yb > 16: return -1
  let scx = 1'i64 shl int(xb); let scy = 1'i64 shl int(yb)
  if requested < 0 or requested > 64 or requested > scx - 1: return -1
  if output.isNil or capacity < 40: return -2
  let mcnt = int(requested) + 1
  let dmax = scx * scy - 1
  var rect: array[65, HintRect]
  var errs: array[130, int64]
  var ixes: array[130, int]
  rect[0] = HintRect(ahi: dmax, dx: scx, flh: scy, fll: scy, xr: scx)
  errs[0] = dmax
  var iq = 0; var it = 0
  var upper = dmax; var lower = 0'i64
  while it < mcnt - 1 and it <= iq:
    let io = ixes[it]; let ma = io; let jo = it + 1
    let parent = rect[ma]
    let dx = parent.dx div 2
    rect[io].dx = dx; rect[jo].dx = dx
    rect[jo].xr = parent.xr; rect[io].xr = rect[io].xl + dx; rect[jo].xl = rect[io].xr
    rect[jo].frl = parent.frl; rect[jo].frh = parent.frh
    let numerator = scy * (scx - rect[io].xr)
    let denominator = scx + rect[io].xr
    let floorValue = numerator div denominator
    let ceilValue = floorValue + (if denominator * floorValue != numerator: 1'i64 else: 0'i64)
    rect[io].frl = floorValue; rect[io].frh = ceilValue
    rect[jo].fll = floorValue; rect[jo].flh = ceilValue
    var tm = (rect[io].fll - rect[io].frh) * (rect[io].dx - 2)
    if tm < 0: tm = 0
    let errio = (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) * (rect[io].dx - 1) - tm
    tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2)
    if tm < 0: tm = 0
    let errjo = (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) * (rect[jo].dx - 1) - tm
    let inc = if errio < errjo: 2 else: 1
    let jnc = 3 - inc
    errs[iq + inc] = errio; ixes[iq + inc] = io
    errs[iq + jnc] = errjo; ixes[iq + jnc] = jo
    if errs[iq + 2] != 0: iq += 2 else: iq += 1
    lower -= parent.alo
    rect[io].alo = rect[io].frl * rect[io].dx; rect[jo].alo = rect[jo].frl * rect[jo].dx
    lower += rect[io].alo + rect[jo].alo
    upper -= parent.ahi
    rect[io].ahi = rect[io].flh * rect[io].dx; rect[jo].ahi = rect[jo].flh * rect[jo].dx
    upper += rect[io].ahi + rect[jo].ahi
    inc it
  let kernelStatus = if it > iq: 1'i64 else: 0'i64
  let result = [kernelStatus, int64(it), lower, upper, upper - lower]
  for i in 0..<5: writeI64Le(output, i * 8, result[i])
  40
