#include <stddef.h>
#include <stdint.h>

enum { MAX_POSITIONS = 960, MAX_INPUT_WORDS = 962, BYTES_PER_POSITION = 8 };
static const uint8_t KNIGHT_FIRST[10] = {0, 0, 0, 0, 1, 1, 1, 2, 2, 3};
static const uint8_t KNIGHT_SECOND[10] = {1, 2, 3, 4, 2, 3, 4, 3, 4, 4};

static void unrank_position(int64_t identifier, uint8_t board[8]) {
    uint64_t remainder = (uint64_t)identifier;
    const size_t odd_bishop = (size_t)(remainder % 4) * 2 + 1;
    remainder /= 4;
    const size_t even_bishop = (size_t)(remainder % 4) * 2;
    remainder /= 4;
    const size_t queen_ordinal = (size_t)(remainder % 6);
    const size_t knight_ordinal = (size_t)(remainder / 6);
    for (size_t file = 0; file < 8; ++file) board[file] = 0;
    board[odd_bishop] = (uint8_t)'B';
    board[even_bishop] = (uint8_t)'B';

    size_t open_files[8], open_count = 0;
    for (size_t file = 0; file < 8; ++file) if (board[file] == 0) open_files[open_count++] = file;
    board[open_files[queen_ordinal]] = (uint8_t)'Q';
    open_count = 0;
    for (size_t file = 0; file < 8; ++file) if (board[file] == 0) open_files[open_count++] = file;
    board[open_files[KNIGHT_FIRST[knight_ordinal]]] = (uint8_t)'N';
    board[open_files[KNIGHT_SECOND[knight_ordinal]]] = (uint8_t)'N';
    const uint8_t final_pieces[3] = {'R', 'K', 'R'};
    size_t next_piece = 0;
    for (size_t file = 0; file < 8; ++file)
        if (board[file] == 0) board[file] = final_pieces[next_piece++];
}

int64_t chess960_scharnagl_position_unrank(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_WORDS) return -1;
    const int64_t count_word = input[0];
    if (count_word < 0 || count_word > MAX_POSITIONS || length != (size_t)count_word + 1) return -1;
    const size_t count = (size_t)count_word;
    for (size_t item = 0; item < count; ++item)
        if (input[item + 1] < 0 || input[item + 1] >= MAX_POSITIONS) return -1;
    const size_t bytes = count * BYTES_PER_POSITION;
    if (bytes != 0 && (output == NULL || capacity < bytes)) return -2;
    for (size_t item = 0; item < count; ++item) {
        uint8_t board[8];
        unrank_position(input[item + 1], board);
        for (size_t file = 0; file < 8; ++file) output[item * 8 + file] = board[file];
    }
    return (int64_t)bytes;
}
