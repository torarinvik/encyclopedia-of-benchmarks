module k_means_clustering_zig;

const usz MIN_POINTS = 2;
const usz MAX_POINTS = 8;
const usz MAX_INPUT_LENGTH = 10;
const usz MAX_MOVES = 64;
const long CENTER_BIAS = 4097;
const long CENTER_BASE = 8194;

fn long k_means_clustering_zig(long* input, usz length) @export("k_means_clustering_zig") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1L;
    if (input[0] < (long)MIN_POINTS || input[0] > (long)MAX_POINTS) return -1L;
    usz point_count = (usz)input[0];
    if (length != point_count + 1) return -1L;

    float[MAX_POINTS] points = zeroed;
    for (usz index = 0; index < point_count; index++) {
        long coordinate = input[index + 1];
        if (coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate)) return -1L;
        points[index] = (float)coordinate;
    }

    float[2] centers = {points[0], points[1]};
    usz[2] old_counts = zeroed;
    for (usz move = 0; move < MAX_MOVES; move++) {
        float[2] sums = zeroed;
        usz[2] counts = zeroed;
        for (usz index = 0; index < point_count; index++) {
            float first_delta = points[index] - centers[0];
            float second_delta = centers[1] - points[index];
            float first_distance = first_delta * first_delta;
            float second_distance = second_delta * second_delta;
            usz cluster = second_distance < first_distance ? 1 : 0;
            sums[cluster] = sums[cluster] + points[index];
            counts[cluster]++;
        }
        if (counts[0] == 0 || counts[1] == 0) return -1L;
        float[2] moved = {
            sums[0] / (float)counts[0],
            sums[1] / (float)counts[1],
        };
        if (moved[0] == centers[0] && moved[1] == centers[1] &&
            counts[0] == old_counts[0] && counts[1] == old_counts[1]) {
            long code0 = (long)(moved[0] * 256.0f) + CENTER_BIAS;
            long code1 = (long)(moved[1] * 256.0f) + CENTER_BIAS;
            if (code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193) return -1L;
            return (code0 * CENTER_BASE + code1) * 81 + (long)counts[0] * 9 + (long)counts[1];
        }
        centers[0] = moved[0];
        centers[1] = moved[1];
        old_counts[0] = counts[0];
        old_counts[1] = counts[1];
    }
    return -2L;
}
