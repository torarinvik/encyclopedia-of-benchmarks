// Check that an integer factor list has no repeated values.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t square_free_factor_list(const std::int64_t *values,
                                                  std::size_t length) noexcept
{
    if (length > 256 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (values[i] == values[j]) return 0;
    }
    return 1;
}
