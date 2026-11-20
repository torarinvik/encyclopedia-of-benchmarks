#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_ROWS = 8;
constexpr int MAX_COLUMNS = 10;
constexpr std::size_t MAX_INPUT = 21;
constexpr int INF = 1000000000;

void store_i64_le(std::uint8_t* output, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

int solve(int rows, int columns, const std::int64_t* weights,
          const int* row_left, const int* row_right) {
    int order[MAX_ROWS]{};
    for (int row = 0; row < rows; ++row) order[row] = row;
    for (int i = 1; i < rows; ++i) {
        const int value = order[i];
        int j = i;
        while (j > 0 && row_left[order[j - 1]] > row_left[value]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = value;
    }

    int grouped_left[MAX_ROWS]{}, grouped_right[MAX_ROWS]{}, groups = 0;
    for (int i = 0; i < rows; ++i) {
        const int row = order[i];
        if (groups == 0 || grouped_left[groups - 1] != row_left[row]) {
            grouped_left[groups] = row_left[row];
            grouped_right[groups++] = row_right[row];
        } else if (row_right[row] < grouped_right[groups - 1]) {
            grouped_right[groups - 1] = row_right[row];
        }
    }
    int retained_left[MAX_ROWS]{}, retained_right[MAX_ROWS]{}, retained = 0;
    int suffix_minimum = columns;
    for (int i = groups - 1; i >= 0; --i) {
        if (grouped_right[i] < suffix_minimum) {
            retained_left[retained] = grouped_left[i];
            retained_right[retained++] = grouped_right[i];
            suffix_minimum = grouped_right[i];
        }
    }

    int column_start[MAX_COLUMNS], column_end[MAX_COLUMNS];
    for (int column = 0; column < columns; ++column) {
        column_start[column] = -1;
        column_end[column] = -1;
    }
    for (int reduced_row = 0; reduced_row < retained; ++reduced_row) {
        const int source = retained - 1 - reduced_row;
        for (int column = retained_left[source]; column <= retained_right[source]; ++column) {
            if (column_start[column] < 0) column_start[column] = reduced_row;
            column_end[column] = reduced_row;
        }
    }

    int distance[MAX_COLUMNS];
    for (int column = 0; column < columns; ++column) {
        distance[column] = INF;
        if (column_start[column] == 0) distance[column] = 0;
    }
    int best = INF;
    for (int from = 0; from < columns; ++from) {
        if (distance[from] == INF) continue;
        if (column_end[from] == retained - 1 && distance[from] + weights[from] < best)
            best = distance[from] + static_cast<int>(weights[from]);
        for (int to = from + 1; to < columns; ++to) {
            if (column_start[to] >= 0 && column_start[to] <= column_end[from] + 1) {
                const int candidate = distance[from] + static_cast<int>(weights[from]);
                if (candidate < distance[to]) distance[to] = candidate;
            }
        }
    }
    return best == INF ? -1 : best;
}
} // namespace

extern "C" std::int64_t strong_c1p_set_cover_shortest_path(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const std::int64_t rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS ||
        length != static_cast<std::size_t>(2 + rows_raw + columns_raw)) return -1;
    const int rows = static_cast<int>(rows_raw), columns = static_cast<int>(columns_raw);
    std::int64_t weights[MAX_COLUMNS]{};
    std::uint64_t masks[MAX_ROWS]{};
    int row_left[MAX_ROWS]{}, row_right[MAX_ROWS]{};
    bool infeasible = false;
    for (int column = 0; column < columns; ++column) {
        if (input[2 + column] < 1 || input[2 + column] > 20) return -1;
        weights[column] = input[2 + column];
    }
    const std::uint64_t allowed = (std::uint64_t{1} << columns) - 1;
    for (int row = 0; row < rows; ++row) {
        const std::int64_t raw = input[2 + columns + row];
        if (raw < 0 || (static_cast<std::uint64_t>(raw) & ~allowed) != 0) return -1;
        masks[row] = static_cast<std::uint64_t>(raw);
        bool seen_one = false, seen_zero_after = false;
        row_left[row] = columns;
        row_right[row] = -1;
        for (int column = 0; column < columns; ++column) {
            if ((masks[row] & (std::uint64_t{1} << column)) != 0) {
                if (seen_zero_after) return -1;
                seen_one = true;
                if (row_left[row] == columns) row_left[row] = column;
                row_right[row] = column;
            } else if (seen_one) {
                seen_zero_after = true;
            }
        }
        if (masks[row] == 0) infeasible = true;
    }
    const int result = infeasible ? -1 : solve(rows, columns, weights, row_left, row_right);
    if (output == nullptr || capacity < 8) return -2;
    const std::uint64_t bits = static_cast<std::uint64_t>(static_cast<std::int64_t>(result));
    for (int byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    return 8;
}
