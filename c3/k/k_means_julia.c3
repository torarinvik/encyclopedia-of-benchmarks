module k_means_julia;

const usz MIN_POINTS = 3;
const usz MAX_POINTS = 8;
const usz MAX_PARSEABLE_INPUT_LENGTH = 10;
const usz MAX_MOVES = 64;
const long CENTER_SCALE = 256;
const long CENTER_BIAS = 4097;
const long CENTER_BASE = 8194;

extern fn double sqrt(double value);

fn long k_means_julia(long* input, usz length) @export("k_means_julia") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < (long)MIN_POINTS || input[0] > (long)MAX_POINTS) return -1L;
    usz point_count = (usz)input[0];
    if (length != point_count + 1) return -1L;

    double[MAX_POINTS] points = zeroed;
    for (usz index = 0; index < point_count; index++) {
        long value = input[index + 1];
        if (value < -16 || value > 16 || (index > 0 && input[index] >= value)) return -1L;
        points[index] = (double)value;
    }

    double[2] centers = {points[0], points[point_count / 2]};
    for (usz move = 0; move < MAX_MOVES; move++) {
        double[2] sums = zeroed;
        usz[2] counts = zeroed;
        for (usz index = 0; index < point_count; index++) {
            double first_delta = points[index] - centers[0];
            double second_delta = points[index] - centers[1];
            double first_distance = sqrt(first_delta * first_delta);
            double second_distance = sqrt(second_delta * second_delta);
            usz cluster = second_distance < first_distance ? 1 : 0;
            sums[cluster] += points[index];
            counts[cluster]++;
        }
        if (counts[0] == 0 || counts[1] == 0) return -1L;
        double[2] moved = {
            sums[0] / (double)counts[0],
            sums[1] / (double)counts[1],
        };
        if (moved[0] == centers[0] && moved[1] == centers[1]) {
            long quantized_first = (long)(moved[0] * (double)CENTER_SCALE);
            long quantized_second = (long)(moved[1] * (double)CENTER_SCALE);
            long code_first = quantized_first + CENTER_BIAS;
            long code_second = quantized_second + CENTER_BIAS;
            if (code_first < 1 || code_first > 8193 || code_second < 1 || code_second > 8193) return -1L;
            return code_first * CENTER_BASE + code_second;
        }
        centers[0] = moved[0];
        centers[1] = moved[1];
    }
    return -2L;
}
