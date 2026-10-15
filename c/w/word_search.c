/* Recursive four-neighbor DFS with a visited set and backtracking. */
#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 36
#define MAX_WORD_LENGTH 15

static int is_letter(int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

static int word_search_visit(const int64_t *input, size_t columns, size_t cells,
                             size_t word_start, size_t word_length,
                             size_t position, size_t word_index, uint8_t *visited)
{
    const size_t board_start = 2;
    if (visited[position] != 0 || input[board_start + position] != input[word_start + word_index])
        return 0;
    visited[position] = 1;
    if (word_index + 1 == word_length) {
        visited[position] = 0;
        return 1;
    }
    const size_t row = position / columns;
    const size_t column = position % columns;
    int found = 0;
    if (row > 0) found = word_search_visit(input, columns, cells, word_start, word_length,
                                           position - columns, word_index + 1, visited);
    if (!found && row + 1 < cells / columns)
        found = word_search_visit(input, columns, cells, word_start, word_length,
                                  position + columns, word_index + 1, visited);
    if (!found && column > 0)
        found = word_search_visit(input, columns, cells, word_start, word_length,
                                  position - 1, word_index + 1, visited);
    if (!found && column + 1 < columns)
        found = word_search_visit(input, columns, cells, word_start, word_length,
                                  position + 1, word_index + 1, visited);
    visited[position] = 0;
    return found;
}

int64_t word_search(const int64_t *input, size_t length)
{
    if (input == NULL || length < 5) return -1;
    if (input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6) return -1;
    const size_t rows = (size_t)input[0], columns = (size_t)input[1];
    const size_t cells = rows * columns;
    const size_t word_length_index = 2 + cells;
    if (length <= word_length_index) return -1;
    const int64_t word_length_value = input[word_length_index];
    if (word_length_value < 1 || word_length_value > MAX_WORD_LENGTH ||
        length != word_length_index + 1 + (size_t)word_length_value) return -1;
    const size_t word_length = (size_t)word_length_value;
    for (size_t index = 0; index < cells; ++index)
        if (!is_letter(input[2 + index])) return -1;
    const size_t word_start = word_length_index + 1;
    for (size_t index = 0; index < word_length; ++index)
        if (!is_letter(input[word_start + index])) return -1;
    if (word_length > cells) return 0;

    uint8_t visited[MAX_CELLS] = {0};
    for (size_t position = 0; position < cells; ++position)
        if (word_search_visit(input, columns, cells, word_start, word_length,
                              position, 0, visited)) return 1;
    return 0;
}
