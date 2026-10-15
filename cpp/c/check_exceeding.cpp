// Check nondecreasing letter gaps after ASCII normalization and filtering.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t check_exceeding(const std::int64_t *values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -2;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;

    int previous_letter = -1;
    int previous_gap = -1;
    for (std::size_t i = 0; i < length; ++i) {
        int letter = static_cast<int>(values[i]);
        if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
        if (letter < 'A' || letter > 'Z') continue;
        if (previous_letter >= 0 && letter != previous_letter) {
            const int gap = letter > previous_letter ? letter - previous_letter : previous_letter - letter;
            if (previous_gap >= 0 && gap < previous_gap) return 0;
            previous_gap = gap;
        }
        previous_letter = letter;
    }
    return 1;
}
