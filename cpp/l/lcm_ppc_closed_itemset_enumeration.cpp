#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 8;
constexpr std::size_t max_rows = 16;
constexpr std::size_t max_records = std::size_t{1} << max_items;
constexpr std::size_t max_words = 1 + 2 * max_records;

struct Context {
    const std::array<std::int64_t, max_rows>& rows;
    std::size_t item_count;
    std::size_t row_count;
    std::int64_t minimum_support;
    std::array<std::int64_t, max_words> words{};
    std::size_t record_count = 0;
};

std::size_t support(const Context& ctx, std::int64_t mask) {
    std::size_t count = 0;
    for (std::size_t row = 0; row < ctx.row_count; ++row)
        if ((ctx.rows[row] & mask) == mask) ++count;
    return count;
}

std::int64_t closure(const Context& ctx, std::int64_t mask) {
    auto common = (std::int64_t{1} << ctx.item_count) - 1;
    for (std::size_t row = 0; row < ctx.row_count; ++row)
        if ((ctx.rows[row] & mask) == mask) common &= ctx.rows[row];
    return common;
}

std::int64_t core_index(const Context& ctx, std::int64_t mask, std::size_t pattern_support) {
    for (std::size_t item = 0; item < ctx.item_count; ++item) {
        const auto prefix_mask = (std::int64_t{1} << (item + 1)) - 1;
        if (support(ctx, mask & prefix_mask) == pattern_support)
            return static_cast<std::int64_t>(item);
    }
    return static_cast<std::int64_t>(ctx.item_count) - 1;
}

void enumerate(Context& ctx, std::int64_t mask, std::size_t pattern_support, std::int64_t core) {
    const auto record = ctx.record_count++;
    ctx.words[1 + 2 * record] = mask;
    ctx.words[2 + 2 * record] = static_cast<std::int64_t>(pattern_support);
    for (auto item = core + 1; item < static_cast<std::int64_t>(ctx.item_count); ++item) {
        const auto bit = std::int64_t{1} << item;
        if ((mask & bit) != 0) continue;
        const auto extended = mask | bit;
        const auto child_support = support(ctx, extended);
        if (static_cast<std::int64_t>(child_support) < ctx.minimum_support) continue;
        const auto child = closure(ctx, extended);
        const auto lower_prefix = bit - 1;
        if ((mask & lower_prefix) != (child & lower_prefix)) continue;
        enumerate(ctx, child, child_support, core_index(ctx, child, child_support));
    }
}

void put_i64_le(std::uint8_t* output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t lcm_ppc_closed_itemset_enumeration(
        const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 3 + max_rows) return -1;
    const auto item_count0 = input[0], row_count0 = input[1], minimum = input[2];
    if (item_count0 < 1 || item_count0 > static_cast<std::int64_t>(max_items) ||
        row_count0 < 1 || row_count0 > static_cast<std::int64_t>(max_rows) ||
        minimum < 1 || minimum > row_count0 || length != 3 + static_cast<std::size_t>(row_count0)) return -1;
    const auto item_count = static_cast<std::size_t>(item_count0);
    const auto row_count = static_cast<std::size_t>(row_count0);
    const auto limit = std::int64_t{1} << item_count;
    std::array<std::int64_t, max_rows> rows{};
    for (std::size_t row = 0; row < row_count; ++row) {
        const auto mask = input[3 + row];
        if (mask < 0 || mask >= limit) return -1;
        rows[row] = mask;
    }

    Context ctx{rows, item_count, row_count, minimum};
    const auto root = closure(ctx, 0);
    enumerate(ctx, root, row_count, -1);
    ctx.words[0] = static_cast<std::int64_t>(ctx.record_count);
    const auto output_bytes = 8 * (1 + 2 * ctx.record_count);
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t word = 0; word < 1 + 2 * ctx.record_count; ++word)
        put_i64_le(output, word, ctx.words[word]);
    return static_cast<std::int64_t>(output_bytes);
}
