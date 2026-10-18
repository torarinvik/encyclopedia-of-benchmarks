module kmeans_rust;

const usz MAX_POINTS = 8;
const usz MAX_INPUT_LENGTH = 10;
const usz MAX_MOVES = 256;

fn long kmeans_rust(long* input, usz length) @export("kmeans_rust") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1L;
    long n_value = input[0];
    if (n_value < 2 || n_value > (long)MAX_POINTS) return -1L;
    usz n = (usz)n_value;
    if (length != n + 1) return -1L;

    double[MAX_POINTS] points = zeroed;
    for (usz index = 0; index < n; index++) {
        long coordinate = input[index + 1];
        if (coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate)) return -1L;
        points[index] = (double)coordinate;
    }

    double[2] centers = {points[0], points[n / 2]};
    long[MAX_POINTS] labels = zeroed;
    for (usz index = 0; index < n; index++) {
        double d0 = points[index] - centers[0];
        double d1 = points[index] - centers[1];
        labels[index] = d1 * d1 < d0 * d0 ? 1L : 0L;
    }

    for (usz move = 0; move < MAX_MOVES; move++) {
        double[2] sums = zeroed;
        usz[2] counts = zeroed;
        for (usz index = 0; index < n; index++) {
            usz cluster = (usz)labels[index];
            sums[cluster] = sums[cluster] + points[index];
            counts[cluster]++;
        }
        if (counts[0] == 0 || counts[1] == 0) return -1L;
        centers[0] = sums[0] / (double)counts[0];
        centers[1] = sums[1] / (double)counts[1];

        long[MAX_POINTS] next_labels = zeroed;
        bool unchanged = true;
        for (usz index = 0; index < n; index++) {
            double d0 = points[index] - centers[0];
            double d1 = points[index] - centers[1];
            next_labels[index] = d1 * d1 < d0 * d0 ? 1L : 0L;
            if (next_labels[index] != labels[index]) unchanged = false;
        }
        if (unchanged) {
            long packed = 0;
            for (usz index = 0; index < n; index++) packed |= next_labels[index] << index;
            return packed;
        }
        for (usz index = 0; index < n; index++) labels[index] = next_labels[index];
    }
    return -2L;
}
