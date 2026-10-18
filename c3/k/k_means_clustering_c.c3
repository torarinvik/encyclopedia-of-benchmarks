module k_means_clustering_c;

const usz MIN_POINTS = 3;
const usz MAX_POINTS = 8;
const usz MAX_INPUT_LENGTH = 18;
const usz MAX_MOVES = 64;
const double CENTER_SCALE = 256.0;
const long CENTER_BIAS = 4097;
const long CENTER_BASE = 8194;

fn long k_means_clustering_c(long* input, usz length) @export("k_means_clustering_c") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1L;
    long n_value = input[0];
    if (n_value < (long)MIN_POINTS || n_value > (long)MAX_POINTS) return -1L;
    usz n = (usz)n_value;
    if (length != 1 + 2 * n) return -1L;

    long[MAX_POINTS] labels = zeroed;
    bool has_zero = false;
    bool has_one = false;
    for (usz index = 0; index < n; index++) {
        long label = input[index + 1];
        long coordinate = input[1 + n + index];
        if (label != 0 && label != 1) return -1L;
        labels[index] = label;
        if (label == 0) has_zero = true;
        if (label == 1) has_one = true;
        if (coordinate < -16 || coordinate > 16 ||
            (index > 0 && input[n + index] >= coordinate)) return -1L;
    }
    if (!has_zero || !has_one) return -1L;

    for (usz move = 0; move < MAX_MOVES; move++) {
        double[2] sums = zeroed;
        usz[2] counts = zeroed;
        for (usz index = 0; index < n; index++) {
            usz cluster = (usz)labels[index];
            double point = (double)input[1 + n + index];
            sums[cluster] = sums[cluster] + point;
            counts[cluster]++;
        }
        if (counts[0] == 0 || counts[1] == 0) return -1L;
        double[2] centers = {
            sums[0] / (double)counts[0],
            sums[1] / (double)counts[1],
        };

        usz changed = 0;
        long[MAX_POINTS] next_labels = zeroed;
        for (usz index = 0; index < n; index++) {
            double point = (double)input[1 + n + index];
            double d0 = point - centers[0];
            double d1 = point - centers[1];
            usz cluster = d1 * d1 < d0 * d0 ? 1 : 0;
            next_labels[index] = (long)cluster;
            if (next_labels[index] != labels[index]) changed++;
        }
        for (usz index = 0; index < n; index++) labels[index] = next_labels[index];
        if (changed == 0) {
            long code0 = (long)(centers[0] * CENTER_SCALE) + CENTER_BIAS;
            long code1 = (long)(centers[1] * CENTER_SCALE) + CENTER_BIAS;
            if (code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193) return -1L;
            return code0 * CENTER_BASE + code1;
        }
    }
    return -2L;
}
