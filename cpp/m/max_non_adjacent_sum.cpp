#include <cstddef>
#include <cstdint>

extern "C" std::int64_t max_non_adjacent_sum(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::int64_t invalid = INT64_MIN;
    if (values == nullptr || length < 1 || length > 100000) return invalid;
    std::int64_t two_back = 0, one_back = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const auto value = values[i];
        if (value < 0 || value > 10000) return invalid;
        const std::int64_t take = two_back + value;
        const std::int64_t current = take > one_back ? take : one_back;
        two_back = one_back;
        one_back = current;
    }
    return one_back;
}
