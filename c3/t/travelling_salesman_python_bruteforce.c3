module travelling_salesman_python_bruteforce;

extern fn double floor(double value);
extern fn double sqrt(double value);

const usz MAX_CITIES = 8;
const double COORDINATE_LIMIT = 16.0;

fn long travelling_salesman_python_bruteforce(double* input, usz input_len,
                                              double* output, usz output_capacity)
    @export("travelling_salesman_python_bruteforce") {
    if (input == null || input_len < 3 || input_len > 17) return -1;
    double raw_count = input[0];
    if (raw_count != raw_count || raw_count < 2.0 || raw_count > 8.0 ||
        raw_count != floor(raw_count)) return -1;
    usz city_count = (usz)raw_count;
    if (input_len != 1 + 2 * city_count) return -1;

    double[8] x, y;
    for (usz city = 0; city < city_count; city++) {
        x[city] = input[1 + 2 * city];
        y[city] = input[2 + 2 * city];
        if (x[city] != x[city] || y[city] != y[city] ||
            x[city] < -COORDINATE_LIMIT || x[city] > COORDINATE_LIMIT ||
            y[city] < -COORDINATE_LIMIT || y[city] > COORDINATE_LIMIT ||
            x[city] != floor(x[city]) || y[city] != floor(y[city])) return -1;
    }

    usz permutation_len = city_count - 1;
    usz[7] order, best_order;
    for (usz i = 0; i < permutation_len; i++) order[i] = i + 1;
    double best_distance = 1.0e300;
    while (true) {
        double total = 0.0;
        usz previous = 0;
        for (usz i = 0; i <= permutation_len; i++) {
            usz next = i == permutation_len ? 0 : order[i];
            double dx = x[next] - x[previous];
            double dy = y[next] - y[previous];
            total += sqrt(dx * dx + dy * dy);
            previous = next;
        }
        if (total < best_distance) {
            best_distance = total;
            for (usz i = 0; i < permutation_len; i++) best_order[i] = order[i];
        }

        usz i = permutation_len;
        while (i > 1 && order[i - 2] >= order[i - 1]) i--;
        if (i <= 1) break;
        usz pivot = i - 2;
        usz j = permutation_len - 1;
        while (order[j] <= order[pivot]) j--;
        usz temp = order[pivot];
        order[pivot] = order[j];
        order[j] = temp;
        usz left = i - 1, right = permutation_len - 1;
        while (left < right) {
            temp = order[left];
            order[left++] = order[right];
            order[right--] = temp;
        }
    }

    double[11] result;
    usz path_len = city_count + 1;
    result[0] = (double)path_len;
    result[1] = 0.0;
    for (usz i = 0; i < permutation_len; i++) result[2 + i] = (double)best_order[i];
    result[path_len] = 0.0;
    result[path_len + 1] = best_distance;
    usz required = city_count + 3;
    if (output == null || output_capacity < required) return -2;
    for (usz i = 0; i < required; i++) output[i] = result[i];
    return (long)required;
}
