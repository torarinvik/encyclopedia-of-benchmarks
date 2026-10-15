// Average pairwise hinge loss for ranked scores.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 256; }

extern "C" double average_margin_ranking_loss(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 5 || length > 2 * max_length + 3) return -1.0e300;
    const auto count_value = values[0];
    const auto margin_value = values[1];
    const auto label_value = values[2];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_length) ||
        length != 2 * static_cast<std::size_t>(count_value) + 3 || margin_value < 0 || margin_value > 1000 ||
        (label_value != 1 && label_value != -1)) return -1.0e300;
    const auto count = static_cast<std::size_t>(count_value);
    double total = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto first = values[index + 3];
        const auto second = values[index + 3 + count];
        if (first < -1000 || first > 1000 || second < -1000 || second > 1000) return -1.0e300;
        const double loss = static_cast<double>(margin_value) - static_cast<double>(label_value) *
                            (static_cast<double>(first) - static_cast<double>(second));
        if (loss > 0.0) total += loss;
    }
    return total / static_cast<double>(count);
}
