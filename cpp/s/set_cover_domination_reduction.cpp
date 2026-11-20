#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_ROWS = 8;
constexpr int MAX_COLUMNS = 8;
constexpr std::size_t MAX_INPUT = 19;
constexpr std::size_t MAX_OUTPUT = 272;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

std::uint64_t column_coverage(const std::array<std::uint64_t, MAX_ROWS>& masks,
                             const std::array<bool, MAX_ROWS>& active_rows,
                             int rows, int column) {
    std::uint64_t coverage = 0;
    for (int row = 0; row < rows; ++row)
        if (active_rows[row] && (masks[row] & (std::uint64_t{1} << column)) != 0)
            coverage |= std::uint64_t{1} << row;
    return coverage;
}
}

extern "C" std::int64_t set_cover_domination_reduction(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const auto rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS ||
        length != static_cast<std::size_t>(2 + rows_raw + columns_raw)) return -1;
    const int rows = static_cast<int>(rows_raw), columns = static_cast<int>(columns_raw);
    std::array<std::int64_t, MAX_COLUMNS> weights{};
    std::array<std::uint64_t, MAX_ROWS> masks{};
    std::array<bool, MAX_ROWS> active_rows{};
    std::array<bool, MAX_COLUMNS> active_columns{};
    for (int column = 0; column < columns; ++column) {
        const auto weight = input[2 + column];
        if (weight < 1 || weight > 20) return -1;
        weights[column] = weight;
        active_columns[column] = true;
    }
    const auto valid_columns = (std::uint64_t{1} << columns) - 1;
    for (int row = 0; row < rows; ++row) {
        const auto raw = input[2 + columns + row];
        if (raw < 0 || (static_cast<std::uint64_t>(raw) & ~valid_columns) != 0) return -1;
        masks[row] = static_cast<std::uint64_t>(raw);
        active_rows[row] = true;
    }

    for (;;) {
        bool changed = false;
        for (int keep = 0; keep < rows && !changed; ++keep) {
            if (!active_rows[keep]) continue;
            for (int drop = 0; drop < rows; ++drop) {
                if (!active_rows[drop] || keep == drop) continue;
                if ((masks[keep] & ~masks[drop]) == 0 && (masks[keep] != masks[drop] || keep < drop)) {
                    active_rows[drop] = false;
                    changed = true;
                    break;
                }
            }
        }
        if (changed) continue;

        for (int drop = 0; drop < columns && !changed; ++drop) {
            if (!active_columns[drop]) continue;
            const auto drop_cover = column_coverage(masks, active_rows, rows, drop);
            for (int keep = 0; keep < columns; ++keep) {
                if (!active_columns[keep] || keep == drop) continue;
                const auto keep_cover = column_coverage(masks, active_rows, rows, keep);
                if ((drop_cover & ~keep_cover) == 0 && weights[drop] >= weights[keep] &&
                    (drop_cover != keep_cover || weights[drop] != weights[keep] || keep < drop)) {
                    active_columns[drop] = false;
                    for (int row = 0; row < rows; ++row) masks[row] &= ~(std::uint64_t{1} << drop);
                    changed = true;
                    break;
                }
            }
        }
        if (changed) continue;

        for (int drop = 0; drop < columns && !changed; ++drop) {
            if (!active_columns[drop]) continue;
            const auto drop_cover = column_coverage(masks, active_rows, rows, drop);
            for (int keep = 0; keep < columns; ++keep) {
                if (!active_columns[keep] || keep == drop) continue;
                const auto keep_cover = column_coverage(masks, active_rows, rows, keep);
                const auto exclusive_rows = drop_cover & ~keep_cover;
                if ((drop_cover & keep_cover) == 0 || exclusive_rows == 0) continue;
                std::uint64_t replacement_columns = 0;
                bool feasible = true;
                for (int row = 0; row < rows; ++row) {
                    if ((exclusive_rows & (std::uint64_t{1} << row)) == 0) continue;
                    int minimum_column = -1;
                    for (int candidate = 0; candidate < columns; ++candidate) {
                        if (!active_columns[candidate] || (masks[row] & (std::uint64_t{1} << candidate)) == 0) continue;
                        if (minimum_column < 0 || weights[candidate] < weights[minimum_column] ||
                            (weights[candidate] == weights[minimum_column] && candidate < minimum_column))
                            minimum_column = candidate;
                    }
                    if (minimum_column < 0) { feasible = false; break; }
                    replacement_columns |= std::uint64_t{1} << minimum_column;
                }
                std::int64_t replacement_cost = weights[keep];
                for (int candidate = 0; candidate < columns; ++candidate)
                    if (replacement_columns & (std::uint64_t{1} << candidate)) replacement_cost += weights[candidate];
                if (feasible && weights[drop] >= replacement_cost) {
                    active_columns[drop] = false;
                    for (int row = 0; row < rows; ++row) masks[row] &= ~(std::uint64_t{1} << drop);
                    changed = true;
                    break;
                }
            }
        }
        if (!changed) break;
    }

    std::array<int, MAX_ROWS> row_ids{};
    std::array<int, MAX_COLUMNS> column_ids{};
    std::array<std::uint64_t, MAX_ROWS> reduced_masks{};
    int reduced_rows = 0, reduced_columns = 0;
    for (int row = 0; row < rows; ++row) if (active_rows[row]) row_ids[reduced_rows++] = row;
    for (int column = 0; column < columns; ++column) if (active_columns[column]) column_ids[reduced_columns++] = column;
    for (int i = 0; i < reduced_rows; ++i)
        for (int j = 0; j < reduced_columns; ++j)
            if (masks[row_ids[i]] & (std::uint64_t{1} << column_ids[j])) reduced_masks[i] |= std::uint64_t{1} << j;

    const auto words = static_cast<std::size_t>(2 + 2 * reduced_rows + 2 * reduced_columns);
    const auto bytes = 8 * words;
    std::array<std::uint8_t, MAX_OUTPUT> staged{};
    std::size_t cursor = 0;
    store_i64_le(staged.data(), 8 * cursor++, reduced_rows);
    store_i64_le(staged.data(), 8 * cursor++, reduced_columns);
    for (int i = 0; i < reduced_rows; ++i) store_i64_le(staged.data(), 8 * cursor++, row_ids[i]);
    for (int i = 0; i < reduced_columns; ++i) store_i64_le(staged.data(), 8 * cursor++, column_ids[i]);
    for (int i = 0; i < reduced_columns; ++i) store_i64_le(staged.data(), 8 * cursor++, weights[column_ids[i]]);
    for (int i = 0; i < reduced_rows; ++i) store_i64_le(staged.data(), 8 * cursor++, static_cast<std::int64_t>(reduced_masks[i]));
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(bytes);
}
