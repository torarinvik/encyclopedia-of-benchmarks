#[derive(Clone, Copy, Default)]
struct HintRect {
    ahi: i64, alo: i64, dx: i64, flh: i64, fll: i64, frh: i64, frl: i64, xl: i64, xr: i64,
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn hint_area_bound_refinement(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    let (xb, yb, requested) = (values[0], values[1], values[2]);
    if !(1..=8).contains(&xb) || !(1..=8).contains(&yb) || xb + yb > 16 { return -1; }
    let scx = 1i64 << xb;
    let scy = 1i64 << yb;
    if requested < 0 || requested > 64 || requested > scx - 1 { return -1; }
    if output.is_null() || capacity < 40 { return -2; }

    let mcnt = requested as usize + 1;
    let dmax = scx * scy - 1;
    let mut rect = [HintRect::default(); 65];
    let mut errs = [0i64; 130];
    let mut ixes = [0usize; 130];
    rect[0] = HintRect { ahi: dmax, alo: 0, dx: scx, flh: scy, fll: scy,
        frh: 0, frl: 0, xl: 0, xr: scx };
    errs[0] = dmax;
    let (mut iq, mut it) = (0usize, 0usize);
    let (mut upper, mut lower) = (dmax, 0i64);
    while it < mcnt - 1 && it <= iq {
        let io = ixes[it];
        let ma = io;
        let jo = it + 1;
        let parent = rect[ma];
        let dx = parent.dx / 2;
        rect[io].dx = dx; rect[jo].dx = dx;
        rect[jo].xr = parent.xr; rect[io].xr = rect[io].xl + dx; rect[jo].xl = rect[io].xr;
        rect[jo].frl = parent.frl; rect[jo].frh = parent.frh;
        let numerator = scy * (scx - rect[io].xr);
        let denominator = scx + rect[io].xr;
        let floor_value = numerator / denominator;
        let ceil_value = floor_value + (if denominator * floor_value != numerator { 1 } else { 0 });
        rect[io].frl = floor_value; rect[io].frh = ceil_value;
        rect[jo].fll = floor_value; rect[jo].flh = ceil_value;

        let mut tm = (rect[io].fll - rect[io].frh) * (rect[io].dx - 2);
        if tm < 0 { tm = 0; }
        let errio = (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) * (rect[io].dx - 1) - tm;
        tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2);
        if tm < 0 { tm = 0; }
        let errjo = (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) * (rect[jo].dx - 1) - tm;
        let inc = if errio < errjo { 2 } else { 1 };
        let jnc = 3 - inc;
        errs[iq + inc] = errio; ixes[iq + inc] = io;
        errs[iq + jnc] = errjo; ixes[iq + jnc] = jo;
        iq += if errs[iq + 2] != 0 { 2 } else { 1 };

        lower -= parent.alo;
        rect[io].alo = rect[io].frl * rect[io].dx; rect[jo].alo = rect[jo].frl * rect[jo].dx;
        lower += rect[io].alo + rect[jo].alo;
        upper -= parent.ahi;
        rect[io].ahi = rect[io].flh * rect[io].dx; rect[jo].ahi = rect[jo].flh * rect[jo].dx;
        upper += rect[io].ahi + rect[jo].ahi;
        it += 1;
    }
    let result = [if it > iq { 1 } else { 0 }, it as i64, lower, upper, upper - lower];
    let bytes = core::slice::from_raw_parts_mut(output, 40);
    for index in 0..5 { write_i64_le(bytes, index * 8, result[index]); }
    40
}
