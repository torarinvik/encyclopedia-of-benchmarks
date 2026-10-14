/* Unit-cost Levenshtein distance over two ASCII byte sequences. */
#include <cstddef>
#include <cstdint>

extern "C" int64_t levenshtein_distance(const int64_t *values, std::size_t length)
{
    if (length < 2) return -1;
    const int64_t left_length_value = values[0];
    const int64_t right_length_value = values[1];
    if (left_length_value < 0 || left_length_value > 255 ||
        right_length_value < 0 || right_length_value > 255) return -1;
    const std::size_t left_length = static_cast<std::size_t>(left_length_value);
    const std::size_t right_length = static_cast<std::size_t>(right_length_value);
    if (length != 2 + left_length + right_length) return -1;
    const int64_t *left = values + 2;
    const int64_t *right = left + left_length;
    for (std::size_t index = 0; index < left_length; ++index) {
        if (left[index] < 0 || left[index] > 127) return -1;
    }
    for (std::size_t index = 0; index < right_length; ++index) {
        if (right[index] < 0 || right[index] > 127) return -1;
    }

    int64_t row[256];
    for (std::size_t column = 0; column <= right_length; ++column) row[column] = static_cast<int64_t>(column);
    for (std::size_t row_index = 1; row_index <= left_length; ++row_index) {
        int64_t diagonal = row[0];
        row[0] = static_cast<int64_t>(row_index);
        for (std::size_t column = 1; column <= right_length; ++column) {
            const int64_t above = row[column];
            const int64_t deletion = above + 1;
            const int64_t insertion = row[column - 1] + 1;
            const int64_t substitution = diagonal + (left[row_index - 1] == right[column - 1] ? 0 : 1);
            int64_t best = deletion < insertion ? deletion : insertion;
            if (substitution < best) best = substitution;
            row[column] = best;
            diagonal = above;
        }
    }
    return row[right_length];
}
