module hint_area_bound_refinement;

struct HintRect { long ahi, alo, dx, flh, fll, frh, frl, xl, xr; }

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long hint_area_bound_refinement(long* input, usz length, char* output, usz capacity)
    @export("hint_area_bound_refinement") {
    if (input == null || length != 3) return -1;
    long xb = input[0], yb = input[1], requested = input[2];
    if (xb < 1 || xb > 8 || yb < 1 || yb > 8 || xb + yb > 16) return -1;
    long scx = 1L << xb, scy = 1L << yb;
    if (requested < 0 || requested > 64 || requested > scx - 1) return -1;
    if (output == null || capacity < 40) return -2;
    usz mcnt = (usz)requested + 1;
    long dmax = scx * scy - 1;
    HintRect[65] rect = {};
    long[130] errs = {};
    usz[130] ixes = {};
    rect[0] = {dmax, 0, scx, scy, scy, 0, 0, 0, scx};
    errs[0] = dmax;
    usz iq = 0, it = 0;
    long upper = dmax, lower = 0;
    while (it < mcnt - 1 && it <= iq) {
        usz io = ixes[it], ma = io, jo = it + 1;
        HintRect parent = rect[ma];
        long dx = parent.dx / 2;
        rect[io].dx = dx; rect[jo].dx = dx;
        rect[jo].xr = parent.xr; rect[io].xr = rect[io].xl + dx; rect[jo].xl = rect[io].xr;
        rect[jo].frl = parent.frl; rect[jo].frh = parent.frh;
        long numerator = scy * (scx - rect[io].xr), denominator = scx + rect[io].xr;
        long floor_value = numerator / denominator;
        long ceil_value = floor_value + (denominator * floor_value != numerator);
        rect[io].frl = floor_value; rect[io].frh = ceil_value;
        rect[jo].fll = floor_value; rect[jo].flh = ceil_value;
        long tm = (rect[io].fll - rect[io].frh) * (rect[io].dx - 2);
        if (tm < 0) tm = 0;
        long errio = (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) * (rect[io].dx - 1) - tm;
        tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2);
        if (tm < 0) tm = 0;
        long errjo = (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) * (rect[jo].dx - 1) - tm;
        usz inc = errio < errjo ? 2 : 1, jnc = 3 - inc;
        errs[iq + inc] = errio; ixes[iq + inc] = io;
        errs[iq + jnc] = errjo; ixes[iq + jnc] = jo;
        if (errs[iq + 2] != 0) iq += 2; else iq += 1;
        lower -= parent.alo; rect[io].alo = rect[io].frl * rect[io].dx; rect[jo].alo = rect[jo].frl * rect[jo].dx;
        lower += rect[io].alo + rect[jo].alo;
        upper -= parent.ahi; rect[io].ahi = rect[io].flh * rect[io].dx; rect[jo].ahi = rect[jo].flh * rect[jo].dx;
        upper += rect[io].ahi + rect[jo].ahi;
        it++;
    }
    long[5] result = {(it > iq ? 1 : 0), (long)it, lower, upper, upper - lower};
    for (usz i = 0; i < 5; i++) write_i64(output, i * 8, result[i]);
    return 40;
}
