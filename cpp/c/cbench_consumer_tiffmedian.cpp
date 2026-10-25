#include <cstddef>
#include <cstdint>

namespace {
constexpr int BIN_SIDE = 32;
constexpr int HISTOGRAM_SIZE = BIN_SIDE * BIN_SIDE * BIN_SIDE;
constexpr int MAX_PALETTE = 8;
constexpr int MAX_PIXELS = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 50;

struct ColorBox { int rmin, rmax, gmin, gmax, bmin, bmax, total; };

int hist_at(const std::int32_t *histogram, int r, int g, int b)
{
    return histogram[(r * BIN_SIDE + g) * BIN_SIDE + b];
}

void shrink_box(const std::int32_t *histogram, ColorBox &box)
{
    int rmin = BIN_SIDE, gmin = BIN_SIDE, bmin = BIN_SIDE;
    int rmax = -1, gmax = -1, bmax = -1;
    for (int r = box.rmin; r <= box.rmax; ++r)
        for (int g = box.gmin; g <= box.gmax; ++g)
            for (int b = box.bmin; b <= box.bmax; ++b)
                if (hist_at(histogram, r, g, b) != 0) {
                    if (r < rmin) rmin = r; if (r > rmax) rmax = r;
                    if (g < gmin) gmin = g; if (g > gmax) gmax = g;
                    if (b < bmin) bmin = b; if (b > bmax) bmax = b;
                }
    box.rmin = rmin; box.rmax = rmax; box.gmin = gmin; box.gmax = gmax;
    box.bmin = bmin; box.bmax = bmax;
}

int largest_box(const ColorBox *boxes, int count)
{
    int selected = -1, largest_total = -1;
    for (int i = 0; i < count; ++i) {
        const ColorBox &box = boxes[i];
        if ((box.rmax > box.rmin || box.gmax > box.gmin || box.bmax > box.bmin) &&
            box.total > largest_total) { selected = i; largest_total = box.total; }
    }
    return selected;
}

void split_box(const std::int32_t *histogram, ColorBox *boxes, int &count, int selected)
{
    ColorBox upper = boxes[selected];
    int rs = upper.rmax - upper.rmin, gs = upper.gmax - upper.gmin, bs = upper.bmax - upper.bmin;
    int axis = (rs >= gs && rs >= bs) ? 0 : (gs >= bs ? 1 : 2);
    int first = axis == 0 ? upper.rmin : axis == 1 ? upper.gmin : upper.bmin;
    int last = axis == 0 ? upper.rmax : axis == 1 ? upper.gmax : upper.bmax;
    int along[BIN_SIDE] = {};
    for (int r = upper.rmin; r <= upper.rmax; ++r)
        for (int g = upper.gmin; g <= upper.gmax; ++g)
            for (int b = upper.bmin; b <= upper.bmax; ++b)
                along[axis == 0 ? r : axis == 1 ? g : b] += hist_at(histogram, r, g, b);
    int median = upper.total / 2, accumulated = 0, split = first;
    while (split <= last) { accumulated += along[split]; if (accumulated >= median) break; ++split; }
    if (split == first) ++split;
    ColorBox lower = upper;
    int lower_total = 0, upper_total = 0;
    for (int bin = first; bin < split; ++bin) lower_total += along[bin];
    for (int bin = split; bin <= last; ++bin) upper_total += along[bin];
    lower.total = lower_total; upper.total = upper_total;
    if (axis == 0) { lower.rmax = split - 1; upper.rmin = split; }
    else if (axis == 1) { lower.gmax = split - 1; upper.gmin = split; }
    else { lower.bmax = split - 1; upper.bmin = split; }
    shrink_box(histogram, lower); shrink_box(histogram, upper);
    boxes[selected] = upper;
    for (int i = count; i > 0; --i) boxes[i] = boxes[i - 1];
    boxes[0] = lower;
    ++count;
}
}

extern "C" std::int64_t cbench_consumer_tiffmedian(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 5 || input_length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t palette_value = input[0], pixel_value = input[1];
    if (palette_value < 1 || palette_value > MAX_PALETTE || pixel_value < 1 || pixel_value > MAX_PIXELS) return -1;
    const int palette_limit = static_cast<int>(palette_value), pixel_count = static_cast<int>(pixel_value);
    if (input_length != 2u + 3u * static_cast<std::size_t>(pixel_count)) return -1;
    for (std::size_t i = 0; i < 3u * static_cast<std::size_t>(pixel_count); ++i)
        if (input[i + 2u] < 0 || input[i + 2u] > 255) return -1;

    std::int32_t histogram[HISTOGRAM_SIZE] = {};
    ColorBox boxes[MAX_PALETTE] = {};
    int rmin = BIN_SIDE, gmin = BIN_SIDE, bmin = BIN_SIDE, rmax = -1, gmax = -1, bmax = -1;
    for (int p = 0; p < pixel_count; ++p) {
        int r = static_cast<int>(input[2 + 3*p] >> 3), g = static_cast<int>(input[3 + 3*p] >> 3), b = static_cast<int>(input[4 + 3*p] >> 3);
        ++histogram[(r*BIN_SIDE+g)*BIN_SIDE+b];
        if (r < rmin) rmin=r; if (r > rmax) rmax=r;
        if (g < gmin) gmin=g; if (g > gmax) gmax=g;
        if (b < bmin) bmin=b; if (b > bmax) bmax=b;
    }
    boxes[0] = {rmin,rmax,gmin,gmax,bmin,bmax,pixel_count};
    int box_count = 1;
    while (box_count < palette_limit) {
        int selected = largest_box(boxes, box_count);
        if (selected < 0) break;
        split_box(histogram, boxes, box_count, selected);
    }
    const std::size_t output_bytes = 1u + 3u * static_cast<std::size_t>(box_count);
    if (output == nullptr || output_capacity < output_bytes) return -2;
    output[0] = static_cast<std::uint8_t>(box_count);
    for (int i=0;i<box_count;++i) {
        output[1+3*i]=static_cast<std::uint8_t>((boxes[i].rmin+boxes[i].rmax)*4);
        output[2+3*i]=static_cast<std::uint8_t>((boxes[i].gmin+boxes[i].gmax)*4);
        output[3+3*i]=static_cast<std::uint8_t>((boxes[i].bmin+boxes[i].bmax)*4);
    }
    return static_cast<std::int64_t>(output_bytes);
}
