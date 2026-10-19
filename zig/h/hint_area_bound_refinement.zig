const HintRect = struct {
    ahi: i64 = 0,
    alo: i64 = 0,
    dx: i64 = 0,
    flh: i64 = 0,
    fll: i64 = 0,
    frh: i64 = 0,
    frl: i64 = 0,
    xl: i64 = 0,
    xr: i64 = 0,
};

fn writeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn hint_area_bound_refinement(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    const xb = input[0]; const yb = input[1]; const requested = input[2];
    if (xb < 1 or xb > 8 or yb < 1 or yb > 8 or xb + yb > 16) return -1;
    const scx: i64 = @as(i64, 1) << @intCast(xb);
    const scy: i64 = @as(i64, 1) << @intCast(yb);
    if (requested < 0 or requested > 64 or requested > scx - 1) return -1;
    if (output == null or capacity < 40) return -2;

    const mcnt: usize = @intCast(requested + 1);
    const dmax = scx * scy - 1;
    var rect = [_]HintRect{.{}} ** 65;
    var errs = [_]i64{0} ** 130;
    var ixes = [_]usize{0} ** 130;
    rect[0] = .{ .ahi = dmax, .dx = scx, .flh = scy, .fll = scy, .xr = scx };
    errs[0] = dmax;
    var iq: usize = 0;
    var it: usize = 0;
    var upper = dmax;
    var lower: i64 = 0;
    while (it < mcnt - 1 and it <= iq) {
        const io = ixes[it];
        const ma = io;
        const jo = it + 1;
        const parent = rect[ma];
        const dx = @divTrunc(parent.dx, 2);
        rect[io].dx = dx; rect[jo].dx = dx;
        rect[jo].xr = parent.xr; rect[io].xr = rect[io].xl + dx; rect[jo].xl = rect[io].xr;
        rect[jo].frl = parent.frl; rect[jo].frh = parent.frh;
        const numerator = scy * (scx - rect[io].xr);
        const denominator = scx + rect[io].xr;
        const floor_value = @divTrunc(numerator, denominator);
        const ceil_increment: i64 = if (denominator * floor_value != numerator) 1 else 0;
        const ceil_value = floor_value + ceil_increment;
        rect[io].frl = floor_value; rect[io].frh = ceil_value;
        rect[jo].fll = floor_value; rect[jo].flh = ceil_value;
        var tm = (rect[io].fll - rect[io].frh) * (rect[io].dx - 2);
        if (tm < 0) tm = 0;
        const errio = (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) * (rect[io].dx - 1) - tm;
        tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2);
        if (tm < 0) tm = 0;
        const errjo = (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) * (rect[jo].dx - 1) - tm;
        const inc: usize = if (errio < errjo) 2 else 1;
        const jnc: usize = 3 - inc;
        errs[iq + inc] = errio; ixes[iq + inc] = io;
        errs[iq + jnc] = errjo; ixes[iq + jnc] = jo;
        if (errs[iq + 2] != 0) iq += 2 else iq += 1;

        lower -= parent.alo;
        rect[io].alo = rect[io].frl * rect[io].dx; rect[jo].alo = rect[jo].frl * rect[jo].dx;
        lower += rect[io].alo + rect[jo].alo;
        upper -= parent.ahi;
        rect[io].ahi = rect[io].flh * rect[io].dx; rect[jo].ahi = rect[jo].flh * rect[jo].dx;
        upper += rect[io].ahi + rect[jo].ahi;
        it += 1;
    }
    const status: i64 = if (it > iq) 1 else 0;
    const result = [5]i64{ status, @intCast(it), lower, upper, upper - lower };
    for (0..5) |index| writeI64Le(output, index * 8, result[index]);
    return 40;
}
