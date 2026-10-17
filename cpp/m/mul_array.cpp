#include <cstddef>
#include <cstdint>

extern "C" std::int64_t mul_array(const std::int64_t *values, std::size_t length)
{
    if (length > 9) return -1;
    if (length == 0) return 1;
    if (values == nullptr) return -1;

    std::int64_t product = 1;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = values[index];
        if (value < 0 || value > 99) return -1;
        product *= value;
    }
    return product;
}
