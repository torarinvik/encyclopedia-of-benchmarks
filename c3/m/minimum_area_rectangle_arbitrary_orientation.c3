module minimum_area_rectangle_arbitrary_orientation;

const usz MAX_N = 16;
const usz MAX_PARSEABLE_LENGTH = 34;
const long INVALID_RESULT = -1L;

fn long minimum_area_rectangle_arbitrary_orientation(long* input, usz length)
        @export("minimum_area_rectangle_arbitrary_orientation") {
    if (input == null || length == 0 || length > MAX_PARSEABLE_LENGTH) return INVALID_RESULT;
    long n_value = input[0];
    if (n_value < 4 || n_value > (long)MAX_N) return INVALID_RESULT;
    usz n = (usz)n_value;
    if (length != 1 + 2 * n) return INVALID_RESULT;

    long[MAX_N] x = zeroed;
    long[MAX_N] y = zeroed;
    for (usz i = 0; i < n; i++) {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (x[i] < -32 || x[i] > 32 || y[i] < -32 || y[i] > 32) return INVALID_RESULT;
        for (usz j = 0; j < i; j++)
            if (x[i] == x[j] && y[i] == y[j]) return INVALID_RESULT;
    }

    long best = -1L;
    for (usz i = 0; i < n; i++) {
        for (usz j = i + 1; j < n; j++) {
            long dx1 = x[i] - x[j], dy1 = y[i] - y[j];
            long mid_x = x[i] + x[j], mid_y = y[i] + y[j];
            long len1 = dx1 * dx1 + dy1 * dy1;
            for (usz k = 0; k < n; k++) {
                for (usz l = k + 1; l < n; l++) {
                    if (k < i || (k == i && l <= j)) continue;
                    if (k == i || k == j || l == i || l == j) continue;
                    if (mid_x != x[k] + x[l] || mid_y != y[k] + y[l]) continue;
                    long dx2 = x[k] - x[l], dy2 = y[k] - y[l];
                    if (len1 != dx2 * dx2 + dy2 * dy2) continue;
                    long cross = dx1 * dy2 - dy1 * dx2;
                    long area2 = cross < 0 ? -cross : cross;
                    if (best < 0 || area2 < best) best = area2;
                }
            }
        }
    }
    return best < 0 ? 0 : best;
}
