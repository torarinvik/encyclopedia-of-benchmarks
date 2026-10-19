package hint_area_bound_refinement

import "core:c"

Hint_Rect :: struct {
	ahi, alo, dx, flh, fll, frh, frl, xl, xr: i64,
}

write_i64_le :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { out[offset + byte] = u8(bits >> u64(byte * 8)) }
}

hint_area_bound_refinement :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	xb, yb, requested := input[0], input[1], input[2]
	if xb < 1 || xb > 8 || yb < 1 || yb > 8 || xb + yb > 16 do return -1
	scx := i64(1) << u64(xb); scy := i64(1) << u64(yb)
	if requested < 0 || requested > 64 || requested > scx - 1 do return -1
	if output == nil || capacity < 40 do return -2
	mcnt := int(requested) + 1
	dmax := scx * scy - 1
	rect: [65]Hint_Rect
	errs: [130]i64
	ixes: [130]int
	rect[0] = Hint_Rect{dmax, 0, scx, scy, scy, 0, 0, 0, scx}
	errs[0] = dmax
	ixes[0] = 0
	iq, it := 0, 0
	upper, lower := dmax, i64(0)
	for it < mcnt - 1 && it <= iq {
		io := ixes[it]; ma := io; jo := it + 1
		parent := rect[ma]
		dx := parent.dx / 2
		rect[io].dx = dx; rect[jo].dx = dx
		rect[jo].xr = parent.xr; rect[io].xr = rect[io].xl + dx; rect[jo].xl = rect[io].xr
		rect[jo].frl = parent.frl; rect[jo].frh = parent.frh
		numerator := scy * (scx - rect[io].xr); denominator := scx + rect[io].xr
		floor_value := numerator / denominator
		ceil_value := floor_value
		if denominator * floor_value != numerator { ceil_value += 1 }
		rect[io].frl = floor_value; rect[io].frh = ceil_value
		rect[jo].fll = floor_value; rect[jo].flh = ceil_value
		tm := (rect[io].fll - rect[io].frh) * (rect[io].dx - 2)
		if tm < 0 { tm = 0 }
		errio := (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) * (rect[io].dx - 1) - tm
		tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2)
		if tm < 0 { tm = 0 }
		errjo := (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) * (rect[jo].dx - 1) - tm
		inc, jnc := 1, 2
		if errio < errjo { inc = 2; jnc = 1 }
		errs[iq + inc] = errio; ixes[iq + inc] = io
		errs[iq + jnc] = errjo; ixes[iq + jnc] = jo
		if errs[iq + 2] != 0 { iq += 2 } else { iq += 1 }
		lower -= parent.alo
		rect[io].alo = rect[io].frl * rect[io].dx; rect[jo].alo = rect[jo].frl * rect[jo].dx
		lower += rect[io].alo + rect[jo].alo
		upper -= parent.ahi
		rect[io].ahi = rect[io].flh * rect[io].dx; rect[jo].ahi = rect[jo].flh * rect[jo].dx
		upper += rect[io].ahi + rect[jo].ahi
		it++
	}
	status := i64(0)
	if it > iq { status = 1 }
	result := [5]i64{status, i64(it), lower, upper, upper - lower}
	for i := 0; i < 5; i++ { write_i64_le(output, i * 8, result[i]) }
	return 40
}
