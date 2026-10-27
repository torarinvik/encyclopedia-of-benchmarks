#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ROWS = 64, MAX_INPUT = 69, MAX_OUTPUT = 1032;
void put_u64(std::uint8_t *out, std::size_t word, std::uint64_t value) {
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(value >> (8 * b));
}
}

extern "C" std::int64_t frequent_itemset_conditional_db_reduction(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 6 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], rows0 = input[1], minimum = input[2], tail = input[3], prefix0 = input[4];
    if (n0 < 1 || n0 > 8 || rows0 < 1 || rows0 > static_cast<std::int64_t>(MAX_ROWS) ||
        minimum < 1 || minimum > rows0 || length != 5 + static_cast<std::size_t>(rows0)) return -1;
    if (tail < -1 || tail >= n0 || prefix0 < 0) return -1;
    const auto n = static_cast<std::size_t>(n0), rows = static_cast<std::size_t>(rows0);
    const std::uint64_t limit = UINT64_C(1) << n, prefix = static_cast<std::uint64_t>(prefix0);
    if (prefix >= limit || (tail == -1 && prefix != 0) ||
        (tail >= 0 && (((prefix >> static_cast<std::size_t>(tail)) & 1U) == 0 ||
                       (prefix >> (static_cast<std::size_t>(tail) + 1)) != 0))) return -1;
    std::uint64_t selected[MAX_ROWS] = {}, support[8] = {};
    std::size_t selected_count = 0;
    for (std::size_t row = 0; row < rows; ++row) {
        if (input[5 + row] < 0 || static_cast<std::uint64_t>(input[5 + row]) >= limit) return -1;
        const auto mask = static_cast<std::uint64_t>(input[5 + row]);
        if ((mask & prefix) != prefix) continue;
        selected[selected_count++] = mask;
        for (std::size_t item = static_cast<std::size_t>(tail + 1); item < n; ++item)
            if ((mask & (UINT64_C(1) << item)) != 0) ++support[item];
    }
    if (selected_count < static_cast<std::size_t>(minimum)) return -1;
    std::uint64_t keep = tail >= 0 ? UINT64_C(1) << static_cast<std::size_t>(tail) : 0;
    for (std::size_t item = static_cast<std::size_t>(tail + 1); item < n; ++item)
        if (support[item] >= static_cast<std::uint64_t>(minimum)) keep |= UINT64_C(1) << item;
    const std::uint64_t below = tail > 0 ? (UINT64_C(1) << static_cast<std::size_t>(tail)) - 1 : 0;
    std::uint64_t masks[MAX_ROWS] = {}, counts[MAX_ROWS] = {};
    std::size_t distinct = 0;
    for (std::size_t row = 0; row < selected_count; ++row) {
        const auto reduced = selected[row] & ~below & keep;
        std::size_t at = 0; while (at < distinct && masks[at] != reduced) ++at;
        if (at == distinct) masks[distinct++] = reduced;
        ++counts[at];
    }
    for (std::size_t i = 1; i < distinct; ++i) {
        const auto mask = masks[i], count = counts[i]; std::size_t j = i;
        while (j > 0 && masks[j - 1] > mask) { masks[j] = masks[j - 1]; counts[j] = counts[j - 1]; --j; }
        masks[j] = mask; counts[j] = count;
    }
    const auto word_count = 1 + 2 * distinct, bytes = 8 * word_count;
    if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    put_u64(output, 0, distinct);
    for (std::size_t i = 0; i < distinct; ++i) { put_u64(output, 1 + 2 * i, masks[i]); put_u64(output, 2 + 2 * i, counts[i]); }
    return static_cast<std::int64_t>(bytes);
}
