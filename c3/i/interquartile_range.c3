module interquartile_range;
const double INVALID_RESULT = -1.0e300;

fn double median(long* values, usz count) {
    if (count % 2 != 0) return (double)values[count / 2];
    return ((double)values[count / 2 - 1] + (double)values[count / 2]) / 2.0;
}

fn double interquartile_range(long* values, usz length) @export("interquartile_range") {
    if (values == null || length < 2 || length > 64) return INVALID_RESULT;
    long[64] sorted;
    for (usz i = 0; i < length; i++) {
        if (values[i] < -1000000 || values[i] > 1000000) return INVALID_RESULT;
        sorted[i] = values[i];
    }
    for (usz i = 1; i < length; i++) {
        long key = sorted[i]; usz j = i;
        while (j > 0 && sorted[j - 1] > key) { sorted[j] = sorted[j - 1]; j--; }
        sorted[j] = key;
    }
    usz half = length / 2;
    usz upper_start = half + length % 2;
    return median(&sorted[upper_start], half) - median(&sorted[0], half);
}
