#include <cstddef>
#include <cstdint>

namespace {
struct Context {
    std::int64_t minimum_support;
    std::int64_t words[511]{};
    std::size_t records = 0;
};

void enumerate(Context& ctx, const std::int64_t* rows, std::size_t row_count,
               std::size_t item_count, std::size_t start_item, std::int64_t prefix) {
    for (std::size_t item = start_item; item < item_count; ++item) {
        const auto bit = std::int64_t{1} << item;
        std::int64_t projected[16]{};
        std::size_t projected_count = 0;
        for (std::size_t row = 0; row < row_count; ++row)
            if ((rows[row] & bit) != 0) projected[projected_count++] = rows[row];
        if (static_cast<std::int64_t>(projected_count) < ctx.minimum_support) continue;
        const auto mask = prefix | bit;
        const auto at = 1 + 2 * ctx.records++;
        ctx.words[at] = mask;
        ctx.words[at + 1] = static_cast<std::int64_t>(projected_count);
        enumerate(ctx, projected, projected_count, item_count, item + 1, mask);
    }
}

void put_i64(std::uint8_t* output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) output[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t frequent_itemset_backtrack(const std::int64_t* input, std::size_t length,
                                                     std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 4 || length > 19) return -1;
    const auto item_count0 = input[0], row_count0 = input[1], minimum = input[2];
    if (item_count0 < 1 || item_count0 > 8 || row_count0 < 1 || row_count0 > 16 ||
        minimum < 1 || minimum > row_count0 || length != 3 + static_cast<std::size_t>(row_count0)) return -1;
    const auto item_count = static_cast<std::size_t>(item_count0);
    const auto row_count = static_cast<std::size_t>(row_count0);
    const auto limit = std::int64_t{1} << item_count;
    std::int64_t rows[16]{};
    for (std::size_t i = 0; i < row_count; ++i) {
        const auto mask = input[3 + i];
        if (mask < 0 || mask >= limit) return -1;
        rows[i] = mask;
    }
    Context ctx{minimum};
    enumerate(ctx, rows, row_count, item_count, 0, 0);
    ctx.words[0] = static_cast<std::int64_t>(ctx.records);
    const auto bytes = 8 * (1 + 2 * ctx.records);
    if (!output || capacity < bytes) return -2;
    for (std::size_t i = 0; i < 1 + 2 * ctx.records; ++i) put_i64(output, i, ctx.words[i]);
    return static_cast<std::int64_t>(bytes);
}
