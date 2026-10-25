#include <stddef.h>
#include <stdint.h>

enum { BIN_SIDE = 32, HISTOGRAM_SIZE = 32 * 32 * 32,
       MAX_PALETTE = 8, MAX_PIXELS = 16, MAX_INPUT_LENGTH = 50,
       MAX_OUTPUT_BYTES = 25 };

typedef struct {
    int rmin, rmax, gmin, gmax, bmin, bmax, total;
} ColorBox;

static int hist_at(const int32_t *histogram, int r, int g, int b)
{
    return histogram[(r * BIN_SIDE + g) * BIN_SIDE + b];
}

static void shrink_box(const int32_t *histogram, ColorBox *box)
{
    int rmin = BIN_SIDE, gmin = BIN_SIDE, bmin = BIN_SIDE;
    int rmax = -1, gmax = -1, bmax = -1;
    for (int r = box->rmin; r <= box->rmax; ++r)
        for (int g = box->gmin; g <= box->gmax; ++g)
            for (int b = box->bmin; b <= box->bmax; ++b)
                if (hist_at(histogram, r, g, b) != 0) {
                    if (r < rmin) rmin = r;
                    if (r > rmax) rmax = r;
                    if (g < gmin) gmin = g;
                    if (g > gmax) gmax = g;
                    if (b < bmin) bmin = b;
                    if (b > bmax) bmax = b;
                }
    box->rmin = rmin; box->rmax = rmax;
    box->gmin = gmin; box->gmax = gmax;
    box->bmin = bmin; box->bmax = bmax;
}

static int largest_box(const ColorBox *boxes, int count)
{
    int selected = -1, largest_total = -1;
    for (int i = 0; i < count; ++i) {
        const ColorBox *box = &boxes[i];
        if ((box->rmax > box->rmin || box->gmax > box->gmin ||
             box->bmax > box->bmin) && box->total > largest_total) {
            selected = i;
            largest_total = box->total;
        }
    }
    return selected;
}

static void split_box(const int32_t *histogram, ColorBox *boxes, int *count,
                      int selected)
{
    ColorBox upper = boxes[selected];
    int axis = 0;
    int rspan = upper.rmax - upper.rmin;
    int gspan = upper.gmax - upper.gmin;
    int bspan = upper.bmax - upper.bmin;
    if (!(rspan >= gspan && rspan >= bspan))
        axis = gspan >= bspan ? 1 : 2;

    int first, last;
    if (axis == 0) { first = upper.rmin; last = upper.rmax; }
    else if (axis == 1) { first = upper.gmin; last = upper.gmax; }
    else { first = upper.bmin; last = upper.bmax; }

    int along[BIN_SIDE] = {0};
    for (int r = upper.rmin; r <= upper.rmax; ++r)
        for (int g = upper.gmin; g <= upper.gmax; ++g)
            for (int b = upper.bmin; b <= upper.bmax; ++b) {
                int bin = axis == 0 ? r : axis == 1 ? g : b;
                along[bin] += hist_at(histogram, r, g, b);
            }

    int median = upper.total / 2;
    int accumulated = 0;
    int split = first;
    while (split <= last) {
        accumulated += along[split];
        if (accumulated >= median) break;
        ++split;
    }
    if (split == first) ++split;

    ColorBox lower = upper;
    int lower_total = 0, upper_total = 0;
    for (int bin = first; bin < split; ++bin) lower_total += along[bin];
    for (int bin = split; bin <= last; ++bin) upper_total += along[bin];
    lower.total = lower_total;
    upper.total = upper_total;
    if (axis == 0) { lower.rmax = split - 1; upper.rmin = split; }
    else if (axis == 1) { lower.gmax = split - 1; upper.gmin = split; }
    else { lower.bmax = split - 1; upper.bmin = split; }
    shrink_box(histogram, &lower);
    shrink_box(histogram, &upper);

    boxes[selected] = upper;
    for (int i = *count; i > 0; --i) boxes[i] = boxes[i - 1];
    boxes[0] = lower;
    ++*count;
}

int64_t cbench_consumer_tiffmedian(const int64_t *input, size_t input_length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 5u || input_length > MAX_INPUT_LENGTH)
        return -1;
    int64_t palette_limit = input[0];
    int64_t pixel_count = input[1];
    if (palette_limit < 1 || palette_limit > MAX_PALETTE ||
        pixel_count < 1 || pixel_count > MAX_PIXELS ||
        input_length != 2u + 3u * (size_t)pixel_count)
        return -1;
    for (size_t i = 0; i < (size_t)pixel_count * 3u; ++i)
        if (input[i + 2u] < 0 || input[i + 2u] > 255) return -1;

    int32_t histogram[HISTOGRAM_SIZE] = {0};
    ColorBox boxes[MAX_PALETTE] = {{0}};
    int rmin = BIN_SIDE, gmin = BIN_SIDE, bmin = BIN_SIDE;
    int rmax = -1, gmax = -1, bmax = -1;
    for (size_t p = 0; p < (size_t)pixel_count; ++p) {
        int r = (int)(input[2u + 3u * p] >> 3);
        int g = (int)(input[3u + 3u * p] >> 3);
        int b = (int)(input[4u + 3u * p] >> 3);
        ++histogram[(r * BIN_SIDE + g) * BIN_SIDE + b];
        if (r < rmin) rmin = r; if (r > rmax) rmax = r;
        if (g < gmin) gmin = g; if (g > gmax) gmax = g;
        if (b < bmin) bmin = b; if (b > bmax) bmax = b;
    }
    boxes[0] = (ColorBox){rmin, rmax, gmin, gmax, bmin, bmax,
                          (int)pixel_count};
    int box_count = 1;
    while (box_count < palette_limit) {
        int selected = largest_box(boxes, box_count);
        if (selected < 0) break;
        split_box(histogram, boxes, &box_count, selected);
    }

    size_t output_bytes = 1u + 3u * (size_t)box_count;
    if (output == NULL || output_capacity < output_bytes) return -2;
    output[0] = (uint8_t)box_count;
    for (int i = 0; i < box_count; ++i) {
        output[1u + 3u * (size_t)i] = (uint8_t)((boxes[i].rmin + boxes[i].rmax) * 4);
        output[2u + 3u * (size_t)i] = (uint8_t)((boxes[i].gmin + boxes[i].gmax) * 4);
        output[3u + 3u * (size_t)i] = (uint8_t)((boxes[i].bmin + boxes[i].bmax) * 4);
    }
    return (int64_t)output_bytes;
}
