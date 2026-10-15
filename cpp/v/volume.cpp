#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t max_dimension = 1000;
}

extern "C" std::int64_t volume(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 4) return invalid_result;
    const std::int64_t operation = input[0];
    const std::int64_t a = input[1], b = input[2], c = input[3];
    if (a < 0 || a > max_dimension || b < 0 || b > max_dimension || c < 0 || c > max_dimension) return invalid_result;
    if (operation == 0) {
        if (b != 0 || c != 0) return invalid_result;
        return a * a * a;
    }
    if (operation == 1) return a * b * c;
    if (operation == 2) {
        const std::int64_t product = a * b * c;
        return product % 2 == 0 ? product / 2 : invalid_result;
    }
    if (operation == 3) {
        const std::int64_t product = a * b * c;
        return product % 3 == 0 ? product / 3 : invalid_result;
    }
    return invalid_result;
}
