module rodinia_hybridsort;

const usz HS_MAX_ITEMS = 64, HS_BINS = 1024;

fn usz hs_bucket(float value, float minimum, float span) {
    int index = (int)(((value - minimum) / span) * 1024.0f);
    if (index < 0) index = 0;
    if (index >= 1024) index = 1023;
    return (usz)index;
}

fn void hs_merge_sort(long* items, long* scratch, usz count) {
    usz width = 1;
    while (width < count) {
        usz left = 0;
        while (left < count) {
            usz middle = left + width; if (middle > count) middle = count;
            usz right = left + 2 * width; if (right > count) right = count;
            usz a = left, b = middle, out = left;
            while (a < middle && b < right) { if (items[a] <= items[b]) scratch[out++] = items[a++]; else scratch[out++] = items[b++]; }
            while (a < middle) scratch[out++] = items[a++];
            while (b < right) scratch[out++] = items[b++];
            left += 2 * width;
        }
        for (usz i = 0; i < count; i++) items[i] = scratch[i];
        width *= 2;
    }
}

fn void hs_put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[offset + b] = (char)(u8)(bits >> (8 * b));
}

fn long rodinia_hybridsort(long* input, usz length, char* output, usz capacity) @export("rodinia_hybridsort") {
    if (input == null || length < 3 || length > 65 || input[0] < 2 || input[0] > 64) return -1;
    usz count = (usz)input[0]; if (length != 1 + count) return -1;
    long[64] items, scratch; long min_raw = 9223372036854775807, max_raw = -9223372036854775807 - 1;
    for (usz i = 0; i < count; i++) {
        long raw = input[1 + i]; if (raw < 0 || raw > 1000000 || raw % 1000 != 0) return -1;
        items[i] = raw; if (raw < min_raw) min_raw = raw; if (raw > max_raw) max_raw = raw;
    }
    if (min_raw == max_raw) return -1;
    usz bytes = count * 8; if (output == null || capacity < bytes) return -2;
    float minimum = (float)min_raw / 1000000.0f, maximum = (float)max_raw / 1000000.0f, span = maximum - minimum;
    usz[1024] histogram, next; usz[1025] offsets; long[64] scattered;
    for (usz i = 0; i < HS_BINS; i++) { histogram[i] = 0; offsets[i] = 0; next[i] = 0; }
    for (usz i = 0; i < count; i++) { float value = (float)items[i] / 1000000.0f; histogram[hs_bucket(value, minimum, span)]++; }
    usz prefix = 0; for (usz bin = 0; bin < HS_BINS; bin++) { offsets[bin] = prefix; prefix += histogram[bin]; next[bin] = offsets[bin]; }
    offsets[HS_BINS] = prefix;
    for (usz i = 0; i < count; i++) { float value = (float)items[i] / 1000000.0f; usz bin = hs_bucket(value, minimum, span); scattered[next[bin]++] = items[i]; }
    for (usz bin = 0; bin < HS_BINS; bin++) { usz size = offsets[bin + 1] - offsets[bin]; if (size != 0) hs_merge_sort(&scattered[offsets[bin]], scratch, size); }
    for (usz i = 0; i < count; i++) hs_put_i64(output, 8 * i, scattered[i]);
    return (long)bytes;
}
