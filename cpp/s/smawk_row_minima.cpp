#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ROWS = 16;
constexpr std::size_t MAX_COLUMNS = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 260;

void smawk(const std::int64_t *matrix, std::size_t column_count,
           std::array<std::int32_t, 2 * MAX_ROWS> &row_work,
           std::size_t row_offset, std::size_t row_count,
           std::array<std::int32_t, 3 * MAX_COLUMNS> &column_work,
           std::size_t input_column_offset, std::size_t input_column_count,
           std::size_t output_column_offset,
           std::array<std::int32_t, MAX_ROWS> &minima)
{
    if (row_count == 0) return;
    if (row_count == 1) {
        const auto row = row_work[row_offset];
        auto best = column_work[input_column_offset];
        for (std::size_t j = 1; j < input_column_count; ++j) {
            const auto candidate = column_work[input_column_offset + j];
            if (matrix[static_cast<std::size_t>(row) * column_count + static_cast<std::size_t>(candidate)]
                < matrix[static_cast<std::size_t>(row) * column_count + static_cast<std::size_t>(best)]) best = candidate;
        }
        minima[static_cast<std::size_t>(row)] = best;
        return;
    }

    std::size_t reduced_count = 0;
    for (std::size_t j = 0; j < input_column_count; ++j) {
        const auto candidate = column_work[input_column_offset + j];
        while (reduced_count > 0) {
            const auto comparison_row = row_work[row_offset + reduced_count - 1];
            const auto previous = column_work[output_column_offset + reduced_count - 1];
            if (matrix[static_cast<std::size_t>(comparison_row) * column_count + static_cast<std::size_t>(candidate)]
                < matrix[static_cast<std::size_t>(comparison_row) * column_count + static_cast<std::size_t>(previous)]) --reduced_count;
            else break;
        }
        if (reduced_count < row_count) column_work[output_column_offset + reduced_count++] = candidate;
    }

    const auto odd_offset = row_offset + row_count;
    std::size_t odd_count = 0;
    for (std::size_t i = 1; i < row_count; i += 2) row_work[odd_offset + odd_count++] = row_work[row_offset + i];
    const auto child_output_offset = output_column_offset + reduced_count;
    smawk(matrix, column_count, row_work, odd_offset, odd_count,
          column_work, output_column_offset, reduced_count, child_output_offset, minima);

    std::size_t start_cursor = 0;
    std::size_t end_cursor = 0;
    for (std::size_t i = 0; i < row_count; i += 2) {
        std::size_t start = 0;
        if (i > 0) {
            const auto target = minima[static_cast<std::size_t>(row_work[row_offset + i - 1])];
            while (start_cursor < reduced_count && column_work[output_column_offset + start_cursor] != target) ++start_cursor;
            start = start_cursor < reduced_count ? start_cursor : reduced_count - 1;
        }
        std::size_t end = reduced_count - 1;
        if (i + 1 < row_count) {
            const auto target = minima[static_cast<std::size_t>(row_work[row_offset + i + 1])];
            if (end_cursor < start) end_cursor = start;
            while (end_cursor < reduced_count && column_work[output_column_offset + end_cursor] != target) ++end_cursor;
            end = end_cursor < reduced_count ? end_cursor : reduced_count - 1;
        }
        const auto row = row_work[row_offset + i];
        auto best = column_work[output_column_offset + start];
        for (std::size_t j = start + 1; j <= end; ++j) {
            const auto candidate = column_work[output_column_offset + j];
            if (matrix[static_cast<std::size_t>(row) * column_count + static_cast<std::size_t>(candidate)]
                < matrix[static_cast<std::size_t>(row) * column_count + static_cast<std::size_t>(best)]) best = candidate;
        }
        minima[static_cast<std::size_t>(row)] = best;
    }
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t smawk_row_minima(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_ROWS)
        || input[1] < 1 || input[1] > static_cast<std::int64_t>(MAX_COLUMNS)) return -1;
    const auto row_count = static_cast<std::size_t>(input[0]);
    const auto column_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + row_count * column_count) return -1;

    std::array<std::int32_t, 2 * MAX_ROWS> row_work{};
    std::array<std::int32_t, 3 * MAX_COLUMNS> column_work{};
    std::array<std::int32_t, MAX_ROWS> minima{};
    for (std::size_t i = 0; i < row_count; ++i) row_work[i] = static_cast<std::int32_t>(i);
    for (std::size_t j = 0; j < column_count; ++j) column_work[j] = static_cast<std::int32_t>(j);
    smawk(input + 2, column_count, row_work, 0, row_count,
          column_work, 0, column_count, MAX_COLUMNS, minima);

    std::array<std::uint8_t, 8 * MAX_ROWS> staged{};
    const auto output_bytes = row_count * 8;
    for (std::size_t i = 0; i < row_count; ++i) store_i64_le(staged.data(), i * 8, minima[i]);
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_bytes);
}
