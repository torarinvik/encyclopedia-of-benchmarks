#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" int64_t max_product_of_three(const int64_t *input, size_t length) {
    constexpr int64_t invalid = std::numeric_limits<int64_t>::min();
    if (input == nullptr || length < 1 || input[0] < 3 || input[0] > 128 || length != static_cast<size_t>(input[0]) + 1) return invalid;
    const size_t n = static_cast<size_t>(input[0]);
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < -1000 || input[i + 1] > 1000) return invalid;
    int64_t max1 = input[1], max2 = -1001, max3 = -1001;
    int64_t min1 = input[1], min2 = 1001;
    for (size_t i = 1; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value > max1) { max3 = max2; max2 = max1; max1 = value; }
        else if (value > max2) { max3 = max2; max2 = value; }
        else if (value > max3) max3 = value;
        if (value < min1) { min2 = min1; min1 = value; }
        else if (value < min2) min2 = value;
    }
    const int64_t product1 = max1 * max2 * max3;
    const int64_t product2 = max1 * min1 * min2;
    return product1 > product2 ? product1 : product2;
}
