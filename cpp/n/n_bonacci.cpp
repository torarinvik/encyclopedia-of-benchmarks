/* Return the final term of a bounded N-bonacci sequence. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t n_bonacci(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 2) return -1;
    const std::int64_t order_value = values[0];
    const std::int64_t count_value = values[1];
    if (order_value < 1 || count_value <= order_value || count_value > 64) return -1;
    const auto order = static_cast<std::size_t>(order_value);
    const auto count = static_cast<std::size_t>(count_value);
    std::array<std::int64_t, 64> terms{};
    terms[order - 1] = 1;
    terms[order] = 1;
    for (std::size_t i = order + 1; i < count; ++i) {
        terms[i] = 2 * terms[i - 1] - terms[i - 1 - order];
    }
    return terms[count - 1];
}
