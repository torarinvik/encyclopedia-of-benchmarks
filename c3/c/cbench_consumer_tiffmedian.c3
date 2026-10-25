module cbench_consumer_tiffmedian;

const int BIN_SIDE = 32;
const int HISTOGRAM_SIZE = 32768;
const int MAX_PALETTE = 8;
const int MAX_PIXELS = 16;
const usz MAX_INPUT_LENGTH = 50;

struct ColorBox { int rmin; int rmax; int gmin; int gmax; int bmin; int bmax; int total; }

fn int hist_at(int* histogram, int r, int g, int b) {
    return histogram[(r * BIN_SIDE + g) * BIN_SIDE + b];
}

fn void shrink_box(int* histogram, ColorBox* box) {
    int rmin = BIN_SIDE, gmin = BIN_SIDE, bmin = BIN_SIDE;
    int rmax = -1, gmax = -1, bmax = -1;
    for (int r = box.rmin; r <= box.rmax; r++)
        for (int g = box.gmin; g <= box.gmax; g++)
            for (int b = box.bmin; b <= box.bmax; b++)
                if (hist_at(histogram, r, g, b) != 0) {
                    if (r < rmin) rmin = r; if (r > rmax) rmax = r;
                    if (g < gmin) gmin = g; if (g > gmax) gmax = g;
                    if (b < bmin) bmin = b; if (b > bmax) bmax = b;
                }
    box.rmin = rmin; box.rmax = rmax; box.gmin = gmin; box.gmax = gmax;
    box.bmin = bmin; box.bmax = bmax;
}

fn int largest_box(ColorBox* boxes, int count) {
    int selected = -1, largest_total = -1;
    for (int i = 0; i < count; i++) {
        ColorBox* box = &boxes[i];
        if ((box.rmax > box.rmin || box.gmax > box.gmin || box.bmax > box.bmin) && box.total > largest_total) {
            selected = i; largest_total = box.total;
        }
    }
    return selected;
}

fn void split_box(int* histogram, ColorBox* boxes, int* count, int selected) {
    ColorBox upper = boxes[selected];
    int rspan = upper.rmax - upper.rmin, gspan = upper.gmax - upper.gmin, bspan = upper.bmax - upper.bmin;
    int axis = 0;
    if (!(rspan >= gspan && rspan >= bspan)) axis = gspan >= bspan ? 1 : 2;
    int first = axis == 0 ? upper.rmin : axis == 1 ? upper.gmin : upper.bmin;
    int last = axis == 0 ? upper.rmax : axis == 1 ? upper.gmax : upper.bmax;
    [32]int along = zeroed;
    for (int r = upper.rmin; r <= upper.rmax; r++)
        for (int g = upper.gmin; g <= upper.gmax; g++)
            for (int b = upper.bmin; b <= upper.bmax; b++) {
                int bin = axis == 0 ? r : axis == 1 ? g : b;
                along[bin] += hist_at(histogram, r, g, b);
            }
    int median = upper.total / 2, accumulated = 0, split = first;
    while (split <= last) { accumulated += along[split]; if (accumulated >= median) break; split++; }
    if (split == first) split++;
    ColorBox lower = upper;
    int lower_total = 0, upper_total = 0;
    for (int bin = first; bin < split; bin++) lower_total += along[bin];
    for (int bin = split; bin <= last; bin++) upper_total += along[bin];
    lower.total = lower_total; upper.total = upper_total;
    if (axis == 0) { lower.rmax = split - 1; upper.rmin = split; }
    else if (axis == 1) { lower.gmax = split - 1; upper.gmin = split; }
    else { lower.bmax = split - 1; upper.bmin = split; }
    shrink_box(histogram, &lower); shrink_box(histogram, &upper);
    boxes[selected] = upper;
    for (int i = *count; i > 0; i--) boxes[i] = boxes[i - 1];
    boxes[0] = lower; *count += 1;
}

fn long cbench_consumer_tiffmedian(long* input, usz input_length, uchar* output, usz output_capacity)
    @export("cbench_consumer_tiffmedian") {
    if (input == null || input_length < 5 || input_length > MAX_INPUT_LENGTH) return -1;
    long palette_value = input[0], pixel_value = input[1];
    if (palette_value < 1 || palette_value > MAX_PALETTE || pixel_value < 1 || pixel_value > MAX_PIXELS) return -1;
    int palette_limit = (int)palette_value, pixel_count = (int)pixel_value;
    if (input_length != 2 + (usz)(3 * pixel_count)) return -1;
    for (usz i = 0; i < (usz)(3 * pixel_count); i++) if (input[i + 2] < 0 || input[i + 2] > 255) return -1;

    [HISTOGRAM_SIZE]int histogram = zeroed;
    [MAX_PALETTE]ColorBox boxes = zeroed;
    int rmin = BIN_SIDE, gmin = BIN_SIDE, bmin = BIN_SIDE, rmax = -1, gmax = -1, bmax = -1;
    for (int p = 0; p < pixel_count; p++) {
        int r = (int)(input[2 + 3*p] >> 3), g = (int)(input[3 + 3*p] >> 3), b = (int)(input[4 + 3*p] >> 3);
        histogram[(r*BIN_SIDE+g)*BIN_SIDE+b]++;
        if (r < rmin) rmin = r; if (r > rmax) rmax = r;
        if (g < gmin) gmin = g; if (g > gmax) gmax = g;
        if (b < bmin) bmin = b; if (b > bmax) bmax = b;
    }
    boxes[0] = ColorBox{rmin, rmax, gmin, gmax, bmin, bmax, pixel_count};
    int box_count = 1;
    while (box_count < palette_limit) {
        int selected = largest_box(&boxes[0], box_count);
        if (selected < 0) break;
        split_box(&histogram[0], &boxes[0], &box_count, selected);
    }
    usz output_bytes = 1 + (usz)(3 * box_count);
    if (output == null || output_capacity < output_bytes) return -2;
    output[0] = (uchar)box_count;
    for (int i = 0; i < box_count; i++) {
        output[1+3*i] = (uchar)((boxes[i].rmin+boxes[i].rmax)*4);
        output[2+3*i] = (uchar)((boxes[i].gmin+boxes[i].gmax)*4);
        output[3+3*i] = (uchar)((boxes[i].bmin+boxes[i].bmax)*4);
    }
    return (long)output_bytes;
}
