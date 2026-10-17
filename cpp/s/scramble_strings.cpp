#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 8;
constexpr std::size_t max_parseable_input_length = 2 * max_length + 3;
constexpr std::size_t memo_size = 9 * 9 * 9;

std::int64_t scramble_rec(const std::int64_t *values, std::size_t base1, std::size_t base2,
                          std::size_t start1, std::size_t start2, std::size_t span, std::int8_t *memo)
{
    const auto slot = (start1 * 9 + start2) * 9 + span;
    if (memo[slot] >= 0) return memo[slot];

    bool same = true;
    for (std::size_t offset = 0; offset < span; ++offset)
        if (values[base1 + start1 + offset] != values[base2 + start2 + offset]) {
            same = false;
            break;
        }
    if (same) {
        memo[slot] = 1;
        return 1;
    }

    int counts[26] = {};
    for (std::size_t offset = 0; offset < span; ++offset) {
        ++counts[values[base1 + start1 + offset] - 'a'];
        --counts[values[base2 + start2 + offset] - 'a'];
    }
    for (int count : counts)
        if (count != 0) {
            memo[slot] = 0;
            return 0;
        }

    for (std::size_t split = 1; split < span; ++split) {
        if (scramble_rec(values, base1, base2, start1, start2, split, memo) &&
            scramble_rec(values, base1, base2, start1 + split, start2 + split, span - split, memo)) {
            memo[slot] = 1;
            return 1;
        }
        if (scramble_rec(values, base1, base2, start1, start2 + span - split, split, memo) &&
            scramble_rec(values, base1, base2, start1 + split, start2, span - split, memo)) {
            memo[slot] = 1;
            return 1;
        }
    }
    memo[slot] = 0;
    return 0;
}
}

extern "C" std::int64_t scramble_strings(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    const auto n_value = values[0];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_length)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 2 * n + 1) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (values[index] < 'a' || values[index] > 'z') return -1;

    std::int8_t memo[memo_size];
    for (auto &entry : memo) entry = -1;
    return scramble_rec(values, 1, 1 + n, 0, 0, n, memo);
}
