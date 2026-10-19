#include <cstddef>
#include <cstdint>

struct HintRect { std::int64_t ahi, alo, dx, flh, fll, frh, frl, xl, xr; };

static void write_i64_le(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) out[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

extern "C" std::int64_t hint_area_bound_refinement(const std::int64_t *input, std::size_t length,
                                                     std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length != 3) return -1;
    const std::int64_t xb = input[0], yb = input[1], requested = input[2];
    if (xb < 1 || xb > 8 || yb < 1 || yb > 8 || xb + yb > 16) return -1;
    const std::int64_t scx = std::int64_t{1} << xb, scy = std::int64_t{1} << yb;
    if (requested < 0 || requested > 64 || requested > scx - 1) return -1;
    if (output == nullptr || capacity < 40) return -2;
    const std::size_t mcnt = static_cast<std::size_t>(requested) + 1;
    const std::int64_t dmax = scx * scy - 1;
    HintRect rect[65] = {};
    std::int64_t errs[130] = {};
    std::size_t ixes[130] = {};
    rect[0] = {dmax, 0, scx, scy, scy, 0, 0, 0, scx};
    errs[0] = dmax;
    std::size_t iq = 0, it = 0;
    std::int64_t upper = dmax, lower = 0;
    while (it < mcnt - 1 && it <= iq) {
        const std::size_t io = ixes[it], ma = io, jo = it + 1;
        const HintRect parent = rect[ma];
        const std::int64_t dx = parent.dx / 2;
        rect[io].dx = rect[jo].dx = dx;
        rect[jo].xr = parent.xr; rect[io].xr = rect[io].xl + dx; rect[jo].xl = rect[io].xr;
        rect[jo].frl = parent.frl; rect[jo].frh = parent.frh;
        const std::int64_t numerator = scy * (scx - rect[io].xr), denominator = scx + rect[io].xr;
        const std::int64_t floor_value = numerator / denominator;
        const std::int64_t ceil_value = floor_value + (denominator * floor_value != numerator);
        rect[io].frl = floor_value; rect[io].frh = ceil_value;
        rect[jo].fll = floor_value; rect[jo].flh = ceil_value;
        std::int64_t tm = (rect[io].fll - rect[io].frh) * (rect[io].dx - 2);
        if (tm < 0) tm = 0;
        const std::int64_t errio = (rect[io].flh - rect[io].frh + rect[io].fll - rect[io].frl) * (rect[io].dx - 1) - tm;
        tm = (rect[jo].fll - rect[jo].frh) * (rect[jo].dx - 2);
        if (tm < 0) tm = 0;
        const std::int64_t errjo = (rect[jo].flh - rect[jo].frh + rect[jo].fll - rect[jo].frl) * (rect[jo].dx - 1) - tm;
        const std::size_t inc = errio < errjo ? 2 : 1, jnc = 3 - inc;
        errs[iq + inc] = errio; ixes[iq + inc] = io; errs[iq + jnc] = errjo; ixes[iq + jnc] = jo;
        iq += static_cast<std::size_t>(errs[iq + 2] != 0) + 1;
        lower -= parent.alo; rect[io].alo = rect[io].frl * rect[io].dx; rect[jo].alo = rect[jo].frl * rect[jo].dx;
        lower += rect[io].alo + rect[jo].alo;
        upper -= parent.ahi; rect[io].ahi = rect[io].flh * rect[io].dx; rect[jo].ahi = rect[jo].flh * rect[jo].dx;
        upper += rect[io].ahi + rect[jo].ahi;
        ++it;
    }
    const std::int64_t result[5] = {it > iq ? 1 : 0, static_cast<std::int64_t>(it), lower, upper, upper - lower};
    for (std::size_t i = 0; i < 5; ++i) write_i64_le(output, i * 8, result[i]);
    return 40;
}
