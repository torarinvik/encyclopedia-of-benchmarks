#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t MAX_N = 12'344;
constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = 12'348;
}

extern "C" std::int64_t sparse_table(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 3 || input[n + 1] < 0 || input[n + 2] < input[n + 1] ||
        input[n + 2] >= static_cast<std::int64_t>(n)) return -1;
    const std::size_t left = static_cast<std::size_t>(input[n + 1]);
    const std::size_t right = static_cast<std::size_t>(input[n + 2]);

    std::size_t levels = 1;
    while ((static_cast<std::size_t>(1) << levels) <= n) ++levels;
    std::vector<std::int64_t> table(levels * n, 0);
    std::vector<std::int64_t> logs(n + 1, -1);
    const std::int64_t *values = input + 1;
    for (std::size_t i = 0; i < n; ++i) {
        table[i] = static_cast<std::int64_t>(i);
        logs[i + 1] = logs[i] + (((i & (i + 1)) == 0) ? 1 : 0);
    }
    std::size_t span = 2;
    for (std::size_t level = 1; level < levels; ++level, span *= 2) {
        const std::size_t half = span / 2;
        for (std::size_t i = 0; i + span <= n; ++i) {
            const std::size_t x = static_cast<std::size_t>(table[(level - 1) * n + i]);
            const std::size_t y = static_cast<std::size_t>(table[(level - 1) * n + i + half]);
            table[level * n + i] = values[x] <= values[y]
                ? static_cast<std::int64_t>(x) : static_cast<std::int64_t>(y);
        }
    }

    const std::size_t query_length = right - left + 1;
    const std::size_t level = static_cast<std::size_t>(logs[query_length]);
    const std::size_t block = static_cast<std::size_t>(1) << level;
    const std::size_t x = static_cast<std::size_t>(table[level * n + left]);
    const std::size_t y = static_cast<std::size_t>(table[level * n + right - block + 1]);
    return values[x] <= values[y] ? static_cast<std::int64_t>(x) : static_cast<std::int64_t>(y);
}
