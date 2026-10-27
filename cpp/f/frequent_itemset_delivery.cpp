#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 8, MAX_ROWS = 64, MAX_INPUT = 69, MAX_OUTPUT = 200;
void put_u64(std::uint8_t *output, std::size_t word, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte) output[word * 8 + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t frequent_itemset_delivery(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 6 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], m0 = input[1], minimum = input[2], tail0 = input[3], prefix0 = input[4];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(MAX_ITEMS) || m0 < 1 || m0 > static_cast<std::int64_t>(MAX_ROWS) ||
        minimum < 1 || minimum > m0 || length != 5 + static_cast<std::size_t>(m0)) return -1;
    const auto n = static_cast<std::size_t>(n0), rows = static_cast<std::size_t>(m0);
    if (tail0 < -1 || tail0 >= n0 || prefix0 < 0) return -1;
    const std::uint64_t limit = UINT64_C(1) << n, prefix = static_cast<std::uint64_t>(prefix0);
    if (prefix >= limit || (tail0 == -1 && prefix != 0) ||
        (tail0 >= 0 && (((prefix >> static_cast<std::size_t>(tail0)) & 1U) == 0 || (prefix >> (static_cast<std::size_t>(tail0) + 1)) != 0))) return -1;
    std::uint64_t occurrences[MAX_ITEMS] = {}, supports[MAX_ITEMS] = {};
    for (std::size_t row = 0; row < rows; ++row) {
        if (input[5 + row] < 0 || static_cast<std::uint64_t>(input[5 + row]) >= limit) return -1;
        const auto mask = static_cast<std::uint64_t>(input[5 + row]);
        if ((mask & prefix) != prefix) continue;
        for (std::size_t item = static_cast<std::size_t>(tail0 + 1); item < n; ++item) {
            if ((mask & (UINT64_C(1) << item)) != 0) {
                occurrences[item] |= UINT64_C(1) << row;
                ++supports[item];
            }
        }
    }
    std::uint64_t words[1 + 3 * MAX_ITEMS] = {};
    std::size_t records = 0;
    for (std::size_t item = static_cast<std::size_t>(tail0 + 1); item < n; ++item) {
        if (supports[item] < static_cast<std::uint64_t>(minimum)) continue;
        const auto at = 1 + 3 * records++;
        words[at] = item; words[at + 1] = occurrences[item]; words[at + 2] = supports[item];
    }
    words[0] = records;
    const auto bytes = 8 * (1 + 3 * records);
    if (bytes > MAX_OUTPUT) return -1;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t word = 0; word < 1 + 3 * records; ++word) put_u64(output, word, words[word]);
    return static_cast<std::int64_t>(bytes);
}
