module online_interval_coloring;

const MAX_INTERVALS: usz = 64;
const MAX_INPUT: usz = 129;

fn void store_i64_le(char* out, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn bool level_fits(long* left, long* right, usz* levels, usz last, usz candidate) {
    for (usz anchor = 0; anchor <= last; ++anchor) {
        long point = left[anchor];
        usz overlap = 0;
        for (usz item = 0; item <= last; ++item) {
            if ((item == last || levels[item] <= candidate) && left[item] <= point && point <= right[item]) ++overlap;
        }
        if (overlap > candidate) return false;
    }
    return true;
}

fn long online_interval_coloring(long* input, usz length, char* output, usz capacity) @export("online_interval_coloring") {
    if (input == null || length < 1 || length > MAX_INPUT || input[0] < 0 || input[0] > 64 || length != 1 + 2*(usz)input[0]) return -1;
    usz n = (usz)input[0];
    long[MAX_INTERVALS] left; long[MAX_INTERVALS] right;
    usz[MAX_INTERVALS] levels; usz[MAX_INTERVALS] local; usz[MAX_INTERVALS] colors;
    for (usz i = 0; i < n; ++i) {
        left[i] = input[1 + 2*i]; right[i] = input[2 + 2*i];
        if (left[i] < -1000 || left[i] > 1000 || right[i] < -1000 || right[i] > 1000 || left[i] > right[i]) return -1;
    }
    usz output_bytes = 8*n;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < n; ++i) {
        usz level = 1;
        while (!level_fits(&left[0], &right[0], &levels[0], i, level)) { ++level; if (level > i+1) return -1; }
        levels[i] = level;
        bool[3] used = zeroed;
        for (usz j = 0; j < i; ++j) if (levels[j] == level && left[j] <= right[i] && left[i] <= right[j] && local[j] < 3) used[local[j]] = true;
        usz color = 0; while (color < 3 && used[color]) ++color;
        if (color == 3) return -1;
        local[i] = color; colors[i] = 3*(level-1)+color;
    }
    for (usz i = 0; i < n; ++i) store_i64_le(output, 8*i, (long)colors[i]);
    return (long)output_bytes;
}
