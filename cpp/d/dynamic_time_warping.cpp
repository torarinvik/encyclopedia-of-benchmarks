#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_series_length = 16;
constexpr std::int64_t max_sample_value = 1000;
constexpr double invalid_result = -1.0e300;
constexpr double unreachable = 1.0e300;
}

extern "C" double dynamic_time_warping(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > 35) return invalid_result;
    const auto first_length_value = values[0];
    const auto second_length_value = values[1];
    const auto band_value = values[2];
    if (first_length_value < 1 || first_length_value > max_series_length ||
        second_length_value < 1 || second_length_value > max_series_length) return invalid_result;
    const auto first_length = static_cast<std::size_t>(first_length_value);
    const auto second_length = static_cast<std::size_t>(second_length_value);
    const auto difference = first_length_value > second_length_value
        ? first_length_value - second_length_value : second_length_value - first_length_value;
    if (band_value < difference || band_value > max_series_length ||
        length != 3 + first_length + second_length) return invalid_result;
    const auto band = static_cast<std::size_t>(band_value);
    for (std::size_t index = 0; index < first_length + second_length; ++index) {
        if (values[3 + index] < -max_sample_value || values[3 + index] > max_sample_value) return invalid_result;
    }

    double rows[2][17];
    for (std::size_t j = 0; j <= second_length; ++j) rows[0][j] = unreachable;
    rows[0][0] = 0.0;
    for (std::size_t i = 1; i <= first_length; ++i) {
        const auto current = i % 2;
        const auto previous = (i - 1) % 2;
        for (std::size_t j = 0; j <= second_length; ++j) rows[current][j] = unreachable;
        const auto start = i > band ? i - band : 1;
        const auto end = i + band < second_length ? i + band : second_length;
        for (std::size_t j = start; j <= end; ++j) {
            auto difference_value = values[3 + i - 1] - values[3 + first_length + j - 1];
            if (difference_value < 0) difference_value = -difference_value;
            auto best = rows[previous][j];
            if (rows[current][j - 1] < best) best = rows[current][j - 1];
            if (rows[previous][j - 1] < best) best = rows[previous][j - 1];
            rows[current][j] = static_cast<double>(difference_value) + best;
        }
    }
    return rows[first_length % 2][second_length];
}
