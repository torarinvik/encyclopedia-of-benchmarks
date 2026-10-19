#include <stddef.h>
#include <stdint.h>

typedef struct {
    int64_t ahi, alo, dx, flh, fll, frh, frl, xl, xr;
} HintRect;

static void write_i64_le(uint8_t *out, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) out[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t hint_area_bound_refinement(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    const int64_t xb = input[0], yb = input[1], requested = input[2];
    if (xb < 1 || xb > 8 || yb < 1 || yb > 8 || xb + yb > 16) return -1;
    const int64_t scx = INT64_C(1) << xb, scy = INT64_C(1) << yb;
    if (requested < 0 || requested > 64 || requested > scx - 1) return -1;
    if (output == NULL || capacity < 40) return -2;

    const size_t mcnt = (size_t)requested + 1;
    const int64_t dmax = scx * scy - 1;
    HintRect rect[65] = {{0}};
    int64_t errs[130] = {0};
    size_t ixes[130] = {0};
    rect[0] = (HintRect){dmax, 0, scx, scy, scy, 0, 0, 0, scx};
    errs[0] = dmax;
    ixes[0] = 0;
    size_t iq = 0, it = 0;
    int64_t upper = dmax, lower = 0;

    while (it < mcnt - 1 && it <= iq) {
        const size_t io = ixes[it], ma = io, jo = it + 1;
        const HintRect parent = rect[ma];
        const int64_t dx = parent.dx / 2;
        rect[io].dx = rect[jo].dx = dx;
        rect[jo].xr = parent.xr;
        rect[io].xr = rect[io].xl + dx;
        rect[jo].xl = rect[io].xr;
        rect[jo].frl = parent.frl;
        rect[jo].frh = parent.frh;

        const int64_t numerator = scy * (scx - rect[io].xr);
        const int64_t denominator = scx + rect[io].xr;
        const int64_t floor_value = numerator / denominator;
        const int64_t ceil_value = floor_value + (denominator * floor_value != numerator);
        rect[io].frl = floor_value;
        rect[io].frh = ceil_value;
        rect[jo].fll = floor_value;
        rect[jo].flh = ceil_value;

        int64_t tm = (rect[io].fll - rect[io].frh) * (rect[io].dx - 2);
        if (tm < 0) tm = 0;
        const int64_t errio = (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) *
                              (rect[io].dx - 1) - tm;
        tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2);
        if (tm < 0) tm = 0;
        const int64_t errjo = (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) *
                              (rect[jo].dx - 1) - tm;
        const size_t inc = errio < errjo ? 2 : 1;
        const size_t jnc = 3 - inc;
        errs[iq + inc] = errio; ixes[iq + inc] = io;
        errs[iq + jnc] = errjo; ixes[iq + jnc] = jo;
        iq += (errs[iq + 2] != 0) + 1;

        lower -= parent.alo;
        rect[io].alo = rect[io].frl * rect[io].dx;
        rect[jo].alo = rect[jo].frl * rect[jo].dx;
        lower += rect[io].alo + rect[jo].alo;
        upper -= parent.ahi;
        rect[io].ahi = rect[io].flh * rect[io].dx;
        rect[jo].ahi = rect[jo].flh * rect[jo].dx;
        upper += rect[io].ahi + rect[jo].ahi;
        ++it;
    }
    const int64_t result[5] = {it > iq ? 1 : 0, (int64_t)it, lower, upper, upper - lower};
    for (size_t i = 0; i < 5; ++i) write_i64_le(output, i * 8, result[i]);
    return 40;
}
