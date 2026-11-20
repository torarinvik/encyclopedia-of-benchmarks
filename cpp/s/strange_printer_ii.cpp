#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t strange_printer_ii(const std::int64_t *input,
                                            std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 39) return -1;
    const auto rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > 6 || columns_raw < 1 || columns_raw > 6) return -1;
    const auto rows = static_cast<std::size_t>(rows_raw);
    const auto columns = static_cast<std::size_t>(columns_raw);
    if (length != 2 + rows * columns) return -1;
    for (std::size_t cell = 0; cell < rows * columns; ++cell) {
        if (input[cell + 2] < 1 || input[cell + 2] > 6) return -1;
    }

    std::array<std::int64_t, 7> first_row, last_row, first_column, last_column;
    std::array<std::int64_t, 7> outgoing{}, indegree{}, queue{};
    first_row.fill(rows_raw);
    last_row.fill(-1);
    first_column.fill(columns_raw);
    last_column.fill(-1);
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            const auto color = static_cast<std::size_t>(input[2 + row * columns + column]);
            if (static_cast<std::int64_t>(row) < first_row[color]) first_row[color] = static_cast<std::int64_t>(row);
            if (static_cast<std::int64_t>(row) > last_row[color]) last_row[color] = static_cast<std::int64_t>(row);
            if (static_cast<std::int64_t>(column) < first_column[color]) first_column[color] = static_cast<std::int64_t>(column);
            if (static_cast<std::int64_t>(column) > last_column[color]) last_column[color] = static_cast<std::int64_t>(column);
        }
    }

    std::int64_t present_count = 0;
    for (std::int64_t color = 1; color <= 6; ++color) {
        if (last_row[static_cast<std::size_t>(color)] < 0) continue;
        ++present_count;
        for (auto row = first_row[color]; row <= last_row[color]; ++row) {
            for (auto column = first_column[color]; column <= last_column[color]; ++column) {
                const auto covered = input[2 + static_cast<std::size_t>(row) * columns + static_cast<std::size_t>(column)];
                const auto bit = std::int64_t{1} << covered;
                if (covered != color && (outgoing[color] & bit) == 0) {
                    outgoing[color] |= bit;
                    ++indegree[static_cast<std::size_t>(covered)];
                }
            }
        }
    }
    std::size_t head = 0, tail = 0;
    for (std::int64_t color = 1; color <= 6; ++color) {
        if (last_row[static_cast<std::size_t>(color)] >= 0 && indegree[static_cast<std::size_t>(color)] == 0)
            queue[tail++] = color;
    }
    std::int64_t processed = 0;
    while (head < tail) {
        const auto color = queue[head++];
        ++processed;
        for (std::int64_t later = 1; later <= 6; ++later) {
            const auto bit = std::int64_t{1} << later;
            if ((outgoing[static_cast<std::size_t>(color)] & bit) != 0) {
                auto &degree = indegree[static_cast<std::size_t>(later)];
                if (--degree == 0) queue[tail++] = later;
            }
        }
    }
    return processed == present_count ? 1 : 0;
}
