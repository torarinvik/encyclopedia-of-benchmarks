module in_static_equilibrium;

const long INVALID_RESULT = -1;
const long MAX_N = 100;
const long MAX_COMPONENT = 1000;

fn long in_static_equilibrium(long* values, usz length) @export("in_static_equilibrium") {
    if (values == null || length < 5) return INVALID_RESULT;
    long n_value = values[0];
    if (n_value < 1 || n_value > MAX_N || length != 1 + 4 * (usz)n_value) return INVALID_RESULT;
    usz n = (usz)n_value;
    long total_moment = 0;
    for (usz i = 0; i < n; i++) {
        long fx = values[1 + i], fy = values[1 + n + i];
        long lx = values[1 + 2 * n + i], ly = values[1 + 3 * n + i];
        if (fx < -MAX_COMPONENT || fx > MAX_COMPONENT || fy < -MAX_COMPONENT || fy > MAX_COMPONENT ||
            lx < -MAX_COMPONENT || lx > MAX_COMPONENT || ly < -MAX_COMPONENT || ly > MAX_COMPONENT) return INVALID_RESULT;
        total_moment += lx * fy - ly * fx;
    }
    return total_moment == 0 ? 1 : 0;
}
