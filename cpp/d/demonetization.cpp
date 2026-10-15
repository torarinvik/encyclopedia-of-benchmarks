/* Count denomination combinations with the source's recursive recurrence. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_amount = 30;
constexpr std::int64_t max_denominations = 4;

std::int64_t ways(std::int64_t amount, const std::int64_t *input, std::int64_t count) noexcept
{
    if (amount < 0 || count < 0) return 0;
    if (amount == 0) return 1;
    if (count == 0) return 0;
    const auto denomination = input[count + 1];
    return ways(amount, input, count - 1) + ways(amount - denomination, input, count);
}
}

extern "C" std::int64_t demonetization(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > max_denominations + 2) return -1;
    const auto amount = input[0];
    const auto count = input[1];
    if (amount < -max_amount || amount > max_amount || count < 0 || count > max_denominations
        || length != static_cast<std::size_t>(count + 2)) return -1;
    for (std::int64_t index = 0; index < count; ++index)
        if (input[index + 2] < 1 || input[index + 2] > max_amount) return -1;
    return ways(amount, input, count);
}
