#include <cstdint>

extern "C" std::int64_t padovan_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > 156) return -1;
    if (index <= 2) return 1;

    std::int64_t a = 1, b = 1, c = 1;
    std::int64_t result = 0;
    for (std::int64_t i = 3; i <= index; ++i) {
        result = a + b;
        a = b;
        b = c;
        c = result;
    }
    return result;
}
