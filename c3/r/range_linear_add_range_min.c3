module range_linear_add_range_min;

const usz MAX_LENGTH = 64;
const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT = 387;
const usz BLOCK_WIDTH = 8;
const usz MAX_BLOCKS = 8;
const long CHECKSUM_OFFSET = 8000000;

fn usz block_end(usz block, usz n) {
    usz end = (block + 1) * BLOCK_WIDTH;
    return end < n ? end : n;
}

fn void rebuild(long* data, long* hx, long* hy, usz* count, usz block, usz n) {
    usz base = block * BLOCK_WIDTH;
    usz size = 0;
    for (usz x = base; x < block_end(block, n); x++) {
        while (size >= 2) {
            usz p = base + size - 2; usz q = base + size - 1;
            long cross = (hx[q] - hx[p]) * (data[x] - hy[p]) -
                         (hy[q] - hy[p]) * ((long)x - hx[p]);
            if (cross > 0) break;
            size--;
        }
        hx[base + size] = (long)x; hy[base + size] = data[x]; size++;
    }
    count[block] = size;
}

fn void push_block(long* data, long* slope, long* intercept, usz block, usz n) {
    usz start = block * BLOCK_WIDTH;
    for (usz i = start; i < block_end(block, n); i++)
        data[i] += slope[block] * (long)i + intercept[block];
    slope[block] = 0; intercept[block] = 0;
}

fn long block_min(long* hx, long* hy, usz* count, long* slope,
                  long* intercept, usz block) {
    usz base = block * BLOCK_WIDTH; usz low = 0; usz high = count[block] - 1;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        long left = hy[base + middle] + slope[block] * hx[base + middle];
        long right = hy[base + middle + 1] + slope[block] * hx[base + middle + 1];
        if (left <= right) high = middle; else low = middle + 1;
    }
    return hy[base + low] + slope[block] * hx[base + low] + intercept[block];
}

fn long range_linear_add_range_min_benchmark(long* input, usz length)
    @export("range_linear_add_range_min_benchmark") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_LENGTH || input[1] < 1 || input[1] > (long)MAX_OPERATIONS) return -1;
    usz n = (usz)input[0]; usz q = (usz)input[1];
    if (length < n + 2) return -1;
    long[MAX_LENGTH] data; long[MAX_LENGTH] hx; long[MAX_LENGTH] hy;
    for (usz i = 0; i < n; i++) {
        if (input[i + 2] < -1000000 || input[i + 2] > 1000000) return -1;
        data[i] = input[i + 2];
    }
    long[MAX_BLOCKS] slope; long[MAX_BLOCKS] intercept; usz[MAX_BLOCKS] hull_count;
    usz blocks = (n + BLOCK_WIDTH - 1) / BLOCK_WIDTH;
    for (usz block = 0; block < blocks; block++) {
        slope[block] = 0; intercept[block] = 0;
        rebuild(&data[0], &hx[0], &hy[0], &hull_count[0], block, n);
    }
    usz cursor = n + 2; long checksum = 0;
    for (usz operation = 0; operation < q; operation++) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor + 4 > length) return -1;
            long left_value = input[cursor++]; long right_value = input[cursor++];
            long add_slope = input[cursor++]; long add_intercept = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > (long)n ||
                add_slope < -99 || add_slope > 99 || add_intercept < -100000 || add_intercept > 100000) return -1;
            usz position = (usz)left_value; usz right = (usz)right_value;
            while (position < right) {
                usz block = position / BLOCK_WIDTH; usz start = block * BLOCK_WIDTH;
                usz end = block_end(block, n);
                if (position == start && end <= right) {
                    slope[block] += add_slope; intercept[block] += add_intercept; position = end;
                } else {
                    push_block(&data[0], &slope[0], &intercept[0], block, n);
                    usz stop = end < right ? end : right;
                    for (usz i = position; i < stop; i++) data[i] += add_slope * (long)i + add_intercept;
                    rebuild(&data[0], &hx[0], &hy[0], &hull_count[0], block, n); position = stop;
                }
            }
        } else if (opcode == 1) {
            if (cursor + 2 > length) return -1;
            long left_value = input[cursor++]; long right_value = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > (long)n) return -1;
            usz position = (usz)left_value; usz right = (usz)right_value; long minimum = 0x7fffffffffffffffL;
            while (position < right) {
                usz block = position / BLOCK_WIDTH; usz start = block * BLOCK_WIDTH;
                usz end = block_end(block, n);
                if (position == start && end <= right) {
                    long candidate = block_min(&hx[0], &hy[0], &hull_count[0], &slope[0], &intercept[0], block);
                    if (candidate < minimum) minimum = candidate; position = end;
                } else {
                    usz stop = end < right ? end : right;
                    for (usz i = position; i < stop; i++) {
                        long candidate = data[i] + slope[block] * (long)i + intercept[block];
                        if (candidate < minimum) minimum = candidate;
                    }
                    position = stop;
                }
            }
            checksum += (long)(operation + 1) * (minimum + CHECKSUM_OFFSET);
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
