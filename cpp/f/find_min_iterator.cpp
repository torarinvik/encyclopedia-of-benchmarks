#include <cstddef>
#include <cstdint>

extern "C" std::int64_t find_min_iterator(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 129) return -1;
    if (input[0] < 0 || input[0] > 128 || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (count == 0) return -1;
    std::int64_t minimum = 2147483647;
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[i + 1];
        if (value < 0 || value > 2147483647) return -1;
        if (value < minimum) minimum = value;
    }
    return minimum;
}
