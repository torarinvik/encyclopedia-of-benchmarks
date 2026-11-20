#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 4, MAX_COLUMNS = 4, CODE_STATES = 6561,
       MAX_STATES = 3 * 4 * CODE_STATES };

static int cell_color(int code) {
    if (code == 0) return -1;
    return code <= 4 ? 0 : 1;
}

static int advance_frontier(const int input_codes[4], int closed, int diagonal,
                            int color, size_t row, size_t column,
                            int output_codes[4], int *output_closed,
                            int *output_diagonal) {
    if (closed & (1 << color)) return 0;
    const int above = input_codes[column];
    const int left = column == 0 ? 0 : input_codes[column - 1];
    if (row != 0 && column != 0 && cell_color(above) == color &&
        cell_color(left) == color && diagonal == color + 1) return 0;

    for (size_t i = 0; i < 4; ++i) output_codes[i] = input_codes[i];
    output_codes[column] = 0;
    const int above_color = cell_color(above);
    const int above_label = above_color == color ? (color == 0 ? above : above - 4) : 0;
    const int left_label = cell_color(left) == color ? (color == 0 ? left : left - 4) : 0;

    int chosen_label = above_label != 0 ? above_label : left_label;
    if (above_label != 0 && left_label != 0 && above_label != left_label) {
        for (size_t i = 0; i < 4; ++i) {
            if (color == 0 && output_codes[i] == left_label) output_codes[i] = above_label;
            if (color == 1 && output_codes[i] == 4 + left_label) output_codes[i] = 4 + above_label;
        }
        chosen_label = above_label;
    }
    if (chosen_label == 0) {
        int maximum = 0;
        for (size_t i = 0; i < 4; ++i) {
            if (cell_color(output_codes[i]) == color) {
                int label = color == 0 ? output_codes[i] : output_codes[i] - 4;
                if (label > maximum) maximum = label;
            }
        }
        chosen_label = maximum + 1;
    }
    output_codes[column] = color == 0 ? chosen_label : 4 + chosen_label;

    *output_closed = closed;
    if (above != 0 && above_color != color) {
        int old_still_present = 0;
        int other_same_color = 0;
        for (size_t i = 0; i < 4; ++i) {
            if (output_codes[i] == above) old_still_present = 1;
            if (cell_color(output_codes[i]) == above_color && output_codes[i] != above)
                other_same_color = 1;
        }
        if (!old_still_present) {
            if (other_same_color) return 0;
            *output_closed |= 1 << above_color;
        }
    }

    int mapping[9] = {0};
    int next_label[2] = {0, 0};
    for (size_t i = 0; i < 4; ++i) {
        int code = output_codes[i];
        if (code == 0) continue;
        if (code <= 4) {
            if (mapping[code] == 0) mapping[code] = ++next_label[0];
            output_codes[i] = mapping[code];
        } else {
            int key = code - 4;
            if (mapping[4 + key] == 0) mapping[4 + key] = 4 + (++next_label[1]);
            output_codes[i] = mapping[4 + key];
        }
    }
    *output_diagonal = above_color < 0 ? 0 : above_color + 1;
    return 1;
}

static size_t encode_state(const int codes[4], int closed, int diagonal) {
    static const size_t powers[4] = {1, 9, 81, 729};
    size_t code_key = 0;
    for (size_t i = 0; i < 4; ++i) code_key += (size_t)codes[i] * powers[i];
    return ((size_t)closed * 3 + (size_t)diagonal) * CODE_STATES + code_key;
}

int64_t connectivity_aware_plug_dp_binary_grid_colorings(const int64_t *input,
                                                          size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t rows_value = input[0], columns_value = input[1];
    if (rows_value < 2 || rows_value > MAX_ROWS || columns_value < 2 ||
        columns_value > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;

    int64_t dp[MAX_STATES] = {0};
    int64_t next[MAX_STATES] = {0};
    dp[0] = 1;
    for (size_t cell = 0; cell < rows * columns; ++cell) {
        const size_t row = cell / columns, column = cell % columns;
        for (size_t state = 0; state < MAX_STATES; ++state) next[state] = 0;
        for (size_t state = 0; state < MAX_STATES; ++state) {
            if (dp[state] == 0) continue;
            size_t code_key = state % CODE_STATES;
            size_t flags = state / CODE_STATES;
            int diagonal = (int)(flags % 3);
            int closed = (int)(flags / 3);
            int codes[4];
            for (size_t i = 0; i < 4; ++i) {
                codes[i] = (int)(code_key % 9);
                code_key /= 9;
            }
            for (int color = 0; color <= 1; ++color) {
                int output_codes[4], output_closed, output_diagonal;
                if (!advance_frontier(codes, closed, diagonal, color, row, column,
                                      output_codes, &output_closed, &output_diagonal)) continue;
                size_t destination = encode_state(output_codes, output_closed, output_diagonal);
                next[destination] += dp[state];
            }
        }
        for (size_t state = 0; state < MAX_STATES; ++state) dp[state] = next[state];
    }

    int64_t total = 0;
    for (size_t state = 0; state < MAX_STATES; ++state) {
        if (dp[state] == 0) continue;
        size_t code_key = state % CODE_STATES;
        size_t flags = state / CODE_STATES;
        int closed = (int)(flags / 3);
        int seen_black[5] = {0}, seen_white[5] = {0};
        int black_components = 0, white_components = 0;
        for (size_t i = 0; i < 4; ++i) {
            int code = (int)(code_key % 9);
            code_key /= 9;
            if (code >= 1 && code <= 4 && !seen_black[code]) {
                seen_black[code] = 1;
                ++black_components;
            } else if (code >= 5 && code <= 8 && !seen_white[code - 4]) {
                seen_white[code - 4] = 1;
                ++white_components;
            }
        }
        if (((closed & 1) ? black_components == 0 : black_components == 1) &&
            ((closed & 2) ? white_components == 0 : white_components == 1))
            total += dp[state];
    }
    return total;
}
