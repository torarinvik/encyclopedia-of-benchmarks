// Deterministic bogo sort for the shared, bounded portable workload.
#include <cstddef>
#include <cstdint>

namespace {
bool bogo_is_sorted(const std::int64_t *values, std::size_t length)
{
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index - 1] > values[index]) return false;
    }
    return true;
}
}

extern "C" void bogo_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    std::uint64_t state = UINT64_C(2654435769);
    while (!bogo_is_sorted(values, length)) {
        for (std::size_t index = length - 1; index > 0; --index) {
            state = (state * UINT64_C(1664525) + UINT64_C(1013904223)) % UINT64_C(4294967296);
            const std::size_t other = static_cast<std::size_t>(
                (state / UINT64_C(65536)) % static_cast<std::uint64_t>(index + 1));
            const std::int64_t temporary = values[index];
            values[index] = values[other];
            values[other] = temporary;
        }
    }
}
