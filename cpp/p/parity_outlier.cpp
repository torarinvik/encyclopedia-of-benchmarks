#include <cstddef>
#include <cstdint>

extern "C" std::int64_t parity_outlier(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 1 || values[0] < 3 || values[0] > 65 || (values[0] & 1) == 0) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != count + 1) return -1;
    std::size_t evens = 0, odds = 0;
    std::int64_t even_value = 0, odd_value = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = values[i + 1];
        if (value < 0 || value > 2147483647) return -1;
        if ((value & 1) == 0) { ++evens; even_value = value; }
        else { ++odds; odd_value = value; }
    }
    if (evens == 1 && odds >= 2) return even_value;
    if (odds == 1 && evens >= 2) return odd_value;
    return -1;
}
