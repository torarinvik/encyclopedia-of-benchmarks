module hint_area_bound_refinement

struct HintRect {
	mut:
		ahi i64
		alo i64
		dx i64
		flh i64
		fll i64
		frh i64
		frl i64
		xl i64
		xr i64
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte++ {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'hint_area_bound_refinement']
pub fn hint_area_bound_refinement(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length != 3 { return -1 }
	unsafe {
		xb := input[0]; yb := input[1]; requested := input[2]
		if xb < 1 || xb > 8 || yb < 1 || yb > 8 || xb + yb > 16 { return -1 }
		scx := i64(1) << int(xb); scy := i64(1) << int(yb)
		if requested < 0 || requested > 64 || requested > scx - 1 { return -1 }
		if output == nil || capacity < 40 { return -2 }
		mcnt := int(requested) + 1
		dmax := scx * scy - 1
		mut rect := []HintRect{len: 65}
		mut errs := []i64{len: 130, init: 0}
		mut ixes := []int{len: 130, init: 0}
		rect[0] = HintRect{ahi: dmax, dx: scx, flh: scy, fll: scy, xr: scx}
		errs[0] = dmax
		mut iq := 0; mut it := 0
		mut upper := dmax; mut lower := i64(0)
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
			if denominator * floor_value != numerator { ceil_value++ }
			rect[io].frl = floor_value; rect[io].frh = ceil_value
			rect[jo].fll = floor_value; rect[jo].flh = ceil_value
			mut tm := (rect[io].fll - rect[io].frh) * (rect[io].dx - 2)
			if tm < 0 { tm = 0 }
			errio := (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) * (rect[io].dx - 1) - tm
			tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2)
			if tm < 0 { tm = 0 }
			errjo := (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) * (rect[jo].dx - 1) - tm
			mut inc := 1; mut jnc := 2
			if errio < errjo { inc = 2; jnc = 1 }
			errs[iq + inc] = errio; ixes[iq + inc] = io
			errs[iq + jnc] = errjo; ixes[iq + jnc] = jo
			if errs[iq + 2] != 0 { iq += 2 } else { iq++ }
			lower -= parent.alo
			rect[io].alo = rect[io].frl * rect[io].dx; rect[jo].alo = rect[jo].frl * rect[jo].dx
			lower += rect[io].alo + rect[jo].alo
			upper -= parent.ahi
			rect[io].ahi = rect[io].flh * rect[io].dx; rect[jo].ahi = rect[jo].flh * rect[jo].dx
			upper += rect[io].ahi + rect[jo].ahi
			it++
		}
		status := if it > iq { i64(1) } else { i64(0) }
		result := [5]i64{status, i64(it), lower, upper, upper - lower}
		for i := 0; i < 5; i++ { write_i64_le(mut output, i * 8, result[i]) }
		return 40
	}
}
