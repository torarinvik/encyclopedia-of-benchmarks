#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 256;
constexpr std::int64_t min_value = -1'000'000;
constexpr std::int64_t max_value = 1'000'000;
constexpr std::int64_t checksum_offset = 1'000'001;
constexpr std::int64_t invalid_result = -1;
}

extern "C" std::int64_t improved_simple_sort(const std::int64_t *values,
                                  std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return invalid_result;
    std::int64_t working[max_length]{};
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < min_value || values[index] > max_value) return invalid_result;
        working[index] = values[index];
    }

    for (std::size_t i = 1; i < length; ++i) {
        for (std::size_t j = 0; j + 1 < length; ++j) {
            if (working[i] < working[j]) {
                const auto temporary = working[i];
                working[i] = working[j];
                working[j] = temporary;
            }
        }
    }
    std::int64_t checksum = 0;
    for (std::size_t index = 0; index < length; ++index) {
        checksum += static_cast<std::int64_t>(index + 1) * (working[index] + checksum_offset);
    }
    return checksum;
}
