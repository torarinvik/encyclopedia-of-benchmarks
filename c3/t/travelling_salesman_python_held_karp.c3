module travelling_salesman_python_held_karp;

extern fn double sqrt(double value);
extern fn double floor(double value);

const usz MAX_CITIES = 8;
const usz MAX_INPUT_VALUES = 17;
const usz MAX_OUTPUT_VALUES = 11;
const usz MAX_MASKS = 256;
const double INF_COST = 1.0e300;

fn long travelling_salesman_dynamic_programming(double* input, usz input_length,
                                               double* output, usz capacity)
    @export("travelling_salesman_dynamic_programming") {
    if (input == null || input_length < 5 || input_length > MAX_INPUT_VALUES) return -1L;
    double n_value = input[0];
    if (n_value != n_value || n_value < 2.0 || n_value > (double)MAX_CITIES || floor(n_value) != n_value) return -1L;
    usz n = (usz)n_value;
    if (input_length != 1 + 2 * n) return -1L;

    double[MAX_CITIES] x = zeroed, y = zeroed;
    for (usz city = 0; city < n; city++) {
        double cx = input[1 + 2 * city];
        double cy = input[2 + 2 * city];
        if (cx != cx || cy != cy || cx < -16.0 || cx > 16.0 || cy < -16.0 || cy > 16.0 ||
            floor(cx) != cx || floor(cy) != cy) return -1L;
        x[city] = cx;
        y[city] = cy;
    }

    double[MAX_CITIES * MAX_CITIES] distances = zeroed;
    for (usz from = 0; from < n; from++) {
        for (usz to = 0; to < n; to++) {
            double dx = x[to] - x[from];
            double dy = y[to] - y[from];
            distances[from * MAX_CITIES + to] = sqrt(dx * dx + dy * dy);
        }
    }

    double[MAX_MASKS * MAX_CITIES] dp;
    for (usz index = 0; index < MAX_MASKS * MAX_CITIES; index++) dp[index] = INF_COST;
    dp[MAX_CITIES] = 0.0;
    usz mask_count = (usz)1 << n;
    for (usz mask = 0; mask < mask_count; mask++) {
        for (usz u = 0; u < n; u++) {
            if ((mask & ((usz)1 << u)) == 0) continue;
            double prefix = dp[mask * MAX_CITIES + u];
            for (usz v = 0; v < n; v++) {
                usz bit = (usz)1 << v;
                if ((mask & bit) != 0) continue;
                usz next_mask = mask | bit;
                double candidate = prefix + distances[u * MAX_CITIES + v];
                if (candidate < dp[next_mask * MAX_CITIES + v])
                    dp[next_mask * MAX_CITIES + v] = candidate;
            }
        }
    }

    usz final_mask = mask_count - 1;
    double minimum = INF_COST;
    usz end_node = n;
    for (usz u = 1; u < n; u++) {
        double candidate = dp[final_mask * MAX_CITIES + u] + distances[u * MAX_CITIES];
        if (minimum > candidate) { minimum = candidate; end_node = u; }
    }
    if (end_node == n) return -1L;

    usz[MAX_CITIES + 1] reverse_path = zeroed;
    usz path_length = 0;
    usz mask = final_mask;
    while (end_node != 0) {
        reverse_path[path_length] = end_node;
        path_length++;
        usz previous_mask = mask ^ ((usz)1 << end_node);
        bool found = false;
        for (usz u = 0; u < n; u++) {
            if ((mask & ((usz)1 << u)) == 0) continue;
            if (dp[mask * MAX_CITIES + end_node] ==
                dp[previous_mask * MAX_CITIES + u] + distances[u * MAX_CITIES + end_node]) {
                mask = previous_mask;
                end_node = u;
                found = true;
                break;
            }
        }
        if (!found || path_length > MAX_CITIES) return -1L;
    }
    reverse_path[path_length] = 0;
    path_length++;
    for (usz left = 0, right = path_length - 1; left < right; left++, right--) {
        usz temporary = reverse_path[left];
        reverse_path[left] = reverse_path[right];
        reverse_path[right] = temporary;
    }
    reverse_path[path_length] = 0;
    path_length++;

    double[MAX_OUTPUT_VALUES] staged = zeroed;
    staged[0] = (double)path_length;
    for (usz index = 0; index < path_length; index++) staged[index + 1] = (double)reverse_path[index];
    staged[path_length + 1] = minimum;
    usz output_size = path_length + 2;
    if (output == null || capacity < output_size) return -2L;
    for (usz index = 0; index < output_size; index++) output[index] = staged[index];
    return (long)output_size;
}
