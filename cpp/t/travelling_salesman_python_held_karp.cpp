#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t travelling_salesman_dynamic_programming(
    const double* input, std::size_t input_length, double* output, std::size_t capacity) noexcept {
    constexpr std::size_t max_cities = 8;
    constexpr std::size_t max_input_values = 17;
    constexpr std::size_t max_output_values = 11;
    constexpr std::size_t max_masks = 256;
    constexpr double inf_cost = 1.0e300;
    if (input == nullptr || input_length < 5 || input_length > max_input_values) return -1;
    const double n_value = input[0];
    if (!std::isfinite(n_value) || n_value < 2.0 || n_value > static_cast<double>(max_cities) || std::trunc(n_value) != n_value) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (input_length != 1 + 2 * n) return -1;

    double x[max_cities]{}, y[max_cities]{};
    for (std::size_t city = 0; city < n; ++city) {
        const double cx = input[1 + 2 * city];
        const double cy = input[2 + 2 * city];
        if (!std::isfinite(cx) || !std::isfinite(cy) || cx < -16.0 || cx > 16.0 || cy < -16.0 || cy > 16.0 ||
            std::trunc(cx) != cx || std::trunc(cy) != cy) return -1;
        x[city] = cx;
        y[city] = cy;
    }

    double distances[max_cities * max_cities]{};
    for (std::size_t from = 0; from < n; ++from) {
        for (std::size_t to = 0; to < n; ++to) {
            const double dx = x[to] - x[from];
            const double dy = y[to] - y[from];
            distances[from * max_cities + to] = std::sqrt(dx * dx + dy * dy);
        }
    }

    double dp[max_masks * max_cities];
    for (double& value : dp) value = inf_cost;
    dp[max_cities] = 0.0;
    const std::size_t mask_count = std::size_t{1} << n;
    for (std::size_t mask = 0; mask < mask_count; ++mask) {
        for (std::size_t u = 0; u < n; ++u) {
            if ((mask & (std::size_t{1} << u)) == 0) continue;
            const double prefix = dp[mask * max_cities + u];
            for (std::size_t v = 0; v < n; ++v) {
                const std::size_t bit = std::size_t{1} << v;
                if ((mask & bit) != 0) continue;
                const std::size_t next_mask = mask | bit;
                const double candidate = prefix + distances[u * max_cities + v];
                if (candidate < dp[next_mask * max_cities + v])
                    dp[next_mask * max_cities + v] = candidate;
            }
        }
    }

    const std::size_t final_mask = mask_count - 1;
    double minimum = inf_cost;
    std::size_t end_node = n;
    for (std::size_t u = 1; u < n; ++u) {
        const double candidate = dp[final_mask * max_cities + u] + distances[u * max_cities];
        if (minimum > candidate) { minimum = candidate; end_node = u; }
    }
    if (end_node == n) return -1;

    std::size_t reverse_path[max_cities + 1]{};
    std::size_t path_length = 0;
    std::size_t mask = final_mask;
    while (end_node != 0) {
        reverse_path[path_length++] = end_node;
        const std::size_t previous_mask = mask ^ (std::size_t{1} << end_node);
        bool found = false;
        for (std::size_t u = 0; u < n; ++u) {
            if ((mask & (std::size_t{1} << u)) == 0) continue;
            if (dp[mask * max_cities + end_node] ==
                dp[previous_mask * max_cities + u] + distances[u * max_cities + end_node]) {
                mask = previous_mask;
                end_node = u;
                found = true;
                break;
            }
        }
        if (!found || path_length > max_cities) return -1;
    }
    reverse_path[path_length++] = 0;
    for (std::size_t left = 0, right = path_length - 1; left < right; ++left, --right) {
        const std::size_t temporary = reverse_path[left];
        reverse_path[left] = reverse_path[right];
        reverse_path[right] = temporary;
    }
    reverse_path[path_length++] = 0;

    double staged[max_output_values]{};
    staged[0] = static_cast<double>(path_length);
    for (std::size_t index = 0; index < path_length; ++index) staged[index + 1] = static_cast<double>(reverse_path[index]);
    staged[path_length + 1] = minimum;
    const std::size_t output_size = path_length + 2;
    if (output == nullptr || capacity < output_size) return -2;
    for (std::size_t index = 0; index < output_size; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_size);
}
