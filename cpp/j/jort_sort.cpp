#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 64; }

extern "C" std::int64_t jort_sort(const std::int64_t *values, std::size_t length) noexcept {
    if (length == 0) return 1;
    if (values == nullptr || length > max_length) return -1;
    std::array<std::int64_t, max_length> copy{};
    for (std::size_t i = 0; i < length; ++i) copy[i] = values[i];
    for (std::size_t i = 2; i < length; ++i) {
        const auto key = copy[i];
        auto position = i;
        while (position > 1 && copy[position - 1] > key) {
            copy[position] = copy[position - 1];
            --position;
        }
        copy[position] = key;
    }
    for (std::size_t i = 0; i < length; ++i) if (copy[i] != values[i]) return 0;
    return 1;
}
