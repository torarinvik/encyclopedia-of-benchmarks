#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 64;
constexpr double invalid_result = -1.0e300;
}

extern "C" double kl_divergence_loss(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 2 + 2 * max_count) return invalid_result;
    const auto actual_count_value = input[0];
    const auto predicted_count_value = input[1];
    if (actual_count_value < 0 || actual_count_value > static_cast<std::int64_t>(max_count) ||
        predicted_count_value < 0 || predicted_count_value > static_cast<std::int64_t>(max_count)) return invalid_result;
    const auto actual_count = static_cast<std::size_t>(actual_count_value);
    const auto predicted_count = static_cast<std::size_t>(predicted_count_value);
    if (length != 2 + actual_count + predicted_count) return invalid_result;

    for (std::size_t i = 0; i < actual_count; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 1'000'000) return invalid_result;
    for (std::size_t i = 0; i < predicted_count; ++i)
        if (input[2 + actual_count + i] < 0 || input[2 + actual_count + i] > 1'000'000) return invalid_result;

    double total = 0.0;
    const auto paired_count = std::min(actual_count, predicted_count);
    for (std::size_t i = 0; i < paired_count; ++i) {
        const double actual = static_cast<double>(input[2 + i]) / 1'000'000.0 + 1e-5;
        const double predicted = static_cast<double>(input[2 + actual_count + i]) / 1'000'000.0 + 1e-5;
        total += actual * std::log(actual / predicted);
    }
    return total;
}
