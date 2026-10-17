module smooth_sort;

const usz MAX_N = 512;
const usz MAX_PARSEABLE_INPUT_LENGTH = 514;
const long MAX_VALUE = 1_000_000;
const long OFFSET = 1_000_001;
const usz[16] LEONARDO = {
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973
};

fn uint trailing_zeros(ulong value) {
    uint count = 0;
    while ((value & 1ul) == 0ul) { value >>= 1; count++; }
    return count;
}

fn void sift(long* values, usz order_arg, usz root_arg) {
    usz order = order_arg, root = root_arg;
    long value = values[root];
    while (order > 1) {
        usz right = root - 1;
        usz left = root - 1 - LEONARDO[order - 2];
        if (!(value < values[left]) && !(value < values[right])) break;
        if (!(values[left] < values[right])) {
            values[root] = values[left]; root = left; order--;
        } else {
            values[root] = values[right]; root = right; order -= 2;
        }
    }
    values[root] = value;
}

fn void trinkle(long* values, ulong p_arg, usz order_arg, usz root_arg, bool trusty_arg) {
    ulong p = p_arg;
    usz order = order_arg, root = root_arg;
    bool trusty = trusty_arg;
    long value = values[root];
    while (p != 1ul) {
        usz stepson = root - LEONARDO[order];
        if (!(value < values[stepson])) break;
        if (!trusty && order > 1) {
            usz right = root - 1;
            usz left = root - 1 - LEONARDO[order - 2];
            if (!(values[right] < values[stepson]) || !(values[left] < values[stepson])) break;
        }
        values[root] = values[stepson]; root = stepson;
        ulong mask = p & ~1ul;
        uint shift = trailing_zeros(mask);
        p >>= shift;
        order += (usz)shift;
        trusty = false;
    }
    if (!trusty) { values[root] = value; sift(values, order, root); }
}

fn void smoothsort(long* values, usz length) {
    if (length < 2) return;
    usz last = length - 1;
    ulong p = 1ul;
    usz pshift = 1, head = 0;
    while (head < last) {
        if ((p & 3ul) == 3ul) {
            sift(values, pshift, head); p >>= 2; pshift += 2;
        } else {
            if (LEONARDO[pshift - 1] >= last - head) trinkle(values, p, pshift, head, false);
            else sift(values, pshift, head);
            if (pshift == 1) { p <<= 1; pshift = 0; }
            else { p <<= pshift - 1; pshift = 1; }
        }
        p |= 1ul;
        head++;
    }
    trinkle(values, p, pshift, head, false);
    while (pshift != 1 || p != 1ul) {
        if (pshift <= 1) {
            ulong mask = p & ~1ul;
            uint shift = trailing_zeros(mask);
            p >>= shift; pshift += (usz)shift;
        } else {
            p <<= 2; p ^= 7ul; pshift -= 2;
            trinkle(values, p >> 1, pshift + 1, head - LEONARDO[pshift] - 1, true);
            trinkle(values, p, pshift, head - 1, true);
        }
        head--;
    }
}

fn long smooth_sort_benchmark(long* input, usz length) @export("smooth_sort_benchmark") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_N) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;

    long[MAX_N] values = {};
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        values[index] = value;
    }
    smoothsort(&values[0], count);
    long checksum = 0;
    for (usz index = 0; index < count; index++)
        checksum += (long)(index + 1) * (values[index] + OFFSET);
    return checksum;
}
