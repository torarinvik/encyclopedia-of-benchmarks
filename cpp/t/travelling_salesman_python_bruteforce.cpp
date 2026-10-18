#include <cmath>
#include <cstddef>
#include <cstdint>

static constexpr std::size_t MAX_CITIES = 8;
static constexpr double COORDINATE_LIMIT = 16.0;

extern "C" std::int64_t travelling_salesman_python_bruteforce(
    const double *input, std::size_t input_len, double *output,
    std::size_t output_capacity) {
    if (input == nullptr || input_len < 3 || input_len > 17) return -1;
    const double raw_count = input[0];
    if (!std::isfinite(raw_count) || raw_count < 2.0 || raw_count > 8.0 ||
        raw_count != std::floor(raw_count)) return -1;
    const std::size_t city_count = static_cast<std::size_t>(raw_count);
    if (input_len != 1 + 2 * city_count) return -1;

    double x[MAX_CITIES], y[MAX_CITIES];
    for (std::size_t city = 0; city < city_count; ++city) {
        x[city] = input[1 + 2 * city];
        y[city] = input[2 + 2 * city];
        if (!std::isfinite(x[city]) || !std::isfinite(y[city]) ||
            std::fabs(x[city]) > COORDINATE_LIMIT || std::fabs(y[city]) > COORDINATE_LIMIT ||
            x[city] != std::floor(x[city]) || y[city] != std::floor(y[city])) return -1;
    }

    const std::size_t permutation_len = city_count - 1;
    std::size_t order[MAX_CITIES - 1], best_order[MAX_CITIES - 1];
    for (std::size_t i = 0; i < permutation_len; ++i) order[i] = i + 1;
    double best_distance = INFINITY;
    for (;;) {
        double total = 0.0;
        std::size_t previous = 0;
        for (std::size_t i = 0; i <= permutation_len; ++i) {
            const std::size_t next = i == permutation_len ? 0 : order[i];
            const double dx = x[next] - x[previous];
            const double dy = y[next] - y[previous];
            total += std::sqrt(dx * dx + dy * dy);
            previous = next;
        }
        if (total < best_distance) {
            best_distance = total;
            for (std::size_t i = 0; i < permutation_len; ++i) best_order[i] = order[i];
        }

        std::size_t i = permutation_len;
        while (i > 1 && order[i - 2] >= order[i - 1]) --i;
        if (i <= 1) break;
        const std::size_t pivot = i - 2;
        std::size_t j = permutation_len - 1;
        while (order[j] <= order[pivot]) --j;
        const std::size_t temp = order[pivot];
        order[pivot] = order[j];
        order[j] = temp;
        std::size_t left = i - 1, right = permutation_len - 1;
        while (left < right) {
            const std::size_t value = order[left];
            order[left++] = order[right];
            order[right--] = value;
        }
    }

    double result[11];
    const std::size_t path_len = city_count + 1;
    result[0] = static_cast<double>(path_len);
    result[1] = 0.0;
    for (std::size_t i = 0; i < permutation_len; ++i)
        result[2 + i] = static_cast<double>(best_order[i]);
    result[path_len] = 0.0;
    result[path_len + 1] = best_distance;
    const std::size_t required = city_count + 3;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(required);
}
