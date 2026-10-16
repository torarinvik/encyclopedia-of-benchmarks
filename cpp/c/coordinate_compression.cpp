// Map values to ranks among sorted distinct coordinates.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_N = 128;
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t coordinate_compression(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity)
{
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    std::int64_t sorted[MAX_N];
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[i + 1];
        if (value < std::numeric_limits<std::int32_t>::min() || value > std::numeric_limits<std::int32_t>::max()) return -1;
        sorted[i] = value;
    }
    if (capacity < n * 8 || (n > 0 && output == nullptr)) return -2;
    std::sort(sorted, sorted + n);
    std::int64_t ranks[MAX_N];
    std::int64_t rank = -1, previous = 0;
    for (std::size_t i = 0; i < n; ++i) {
        if (i == 0 || sorted[i] != previous) ++rank;
        ranks[i] = rank;
        previous = sorted[i];
    }
    for (std::size_t i = 0; i < n; ++i) {
        const auto *begin = sorted;
        const auto *end = sorted + n;
        const auto index = static_cast<std::size_t>(std::lower_bound(begin, end, input[i + 1]) - begin);
        put_i64_le(output, i * 8, ranks[index]);
    }
    return static_cast<std::int64_t>(n * 8);
}
