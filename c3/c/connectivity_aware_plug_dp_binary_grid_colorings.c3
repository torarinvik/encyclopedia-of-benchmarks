module connectivity_aware_plug_dp_binary_grid_colorings;

const usz MAX_STATES = 78732;
const usz CODE_STATES = 6561;

fn long cell_color(long code) {
    if (code == 0) return -1;
    return code <= 4 ? 0 : 1;
}

fn bool advance_frontier(long* input_codes, long closed, long diagonal,
                         long color, usz row, usz column, long* output_codes,
                         long* output_closed, long* output_diagonal) {
    if ((closed & (1 << color)) != 0) return false;
    long above = input_codes[column];
    long left = column == 0 ? 0 : input_codes[column - 1];
    if (row != 0 && column != 0 && cell_color(above) == color &&
        cell_color(left) == color && diagonal == color + 1) return false;

    for (usz i = 0; i < 4; i++) output_codes[i] = input_codes[i];
    output_codes[column] = 0;
    long above_color = cell_color(above);
    long above_label = above_color == color ? (color == 0 ? above : above - 4) : 0;
    long left_label = cell_color(left) == color ? (color == 0 ? left : left - 4) : 0;
    long chosen_label = above_label != 0 ? above_label : left_label;
    if (above_label != 0 && left_label != 0 && above_label != left_label) {
        for (usz i = 0; i < 4; i++) {
            if (color == 0 && output_codes[i] == left_label) output_codes[i] = above_label;
            if (color == 1 && output_codes[i] == 4 + left_label) output_codes[i] = 4 + above_label;
        }
        chosen_label = above_label;
    }
    if (chosen_label == 0) {
        long maximum = 0;
        for (usz i = 0; i < 4; i++) {
            if (cell_color(output_codes[i]) == color) {
                long label = color == 0 ? output_codes[i] : output_codes[i] - 4;
                if (label > maximum) maximum = label;
            }
        }
        chosen_label = maximum + 1;
    }
    output_codes[column] = color == 0 ? chosen_label : 4 + chosen_label;

    *output_closed = closed;
    if (above != 0 && above_color != color) {
        bool old_still_present = false, other_same_color = false;
        for (usz i = 0; i < 4; i++) {
            if (output_codes[i] == above) old_still_present = true;
            if (cell_color(output_codes[i]) == above_color && output_codes[i] != above)
                other_same_color = true;
        }
        if (!old_still_present) {
            if (other_same_color) return false;
            *output_closed = closed | (1 << above_color);
        }
    }

    long[9] mapping;
    long next_black = 0, next_white = 0;
    for (usz i = 0; i < 9; i++) mapping[i] = 0;
    for (usz i = 0; i < 4; i++) {
        long code = output_codes[i];
        if (code == 0) continue;
        if (code <= 4) {
            usz key = (usz)code;
            if (mapping[key] == 0) { next_black++; mapping[key] = next_black; }
            output_codes[i] = mapping[key];
        } else {
            usz key = (usz)code;
            if (mapping[key] == 0) { next_white++; mapping[key] = 4 + next_white; }
            output_codes[i] = mapping[key];
        }
    }
    *output_diagonal = above_color < 0 ? 0 : above_color + 1;
    return true;
}

fn usz encode_state(long* codes, long closed, long diagonal) {
    usz[4] powers = {1, 9, 81, 729};
    usz code_key = 0;
    for (usz i = 0; i < 4; i++) code_key += (usz)codes[i] * powers[i];
    return ((usz)closed * 3 + (usz)diagonal) * CODE_STATES + code_key;
}

fn long connectivity_aware_plug_dp_binary_grid_colorings(long* input, usz length)
        @export("connectivity_aware_plug_dp_binary_grid_colorings") {
    if (input == null || length != 2) return -1;
    long rows_value = input[0], columns_value = input[1];
    if (rows_value < 2 || rows_value > 4 || columns_value < 2 || columns_value > 4) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    long[MAX_STATES] dp, next;
    for (usz i = 0; i < MAX_STATES; i++) { dp[i] = 0; next[i] = 0; }
    dp[0] = 1;
    for (usz cell = 0; cell < rows * columns; cell++) {
        usz row = cell / columns, column = cell % columns;
        for (usz state = 0; state < MAX_STATES; state++) next[state] = 0;
        for (usz state = 0; state < MAX_STATES; state++) {
            if (dp[state] == 0) continue;
            usz code_key = state % CODE_STATES;
            usz flags = state / CODE_STATES;
            long diagonal = (long)(flags % 3), closed = (long)(flags / 3);
            long[4] codes;
            for (usz i = 0; i < 4; i++) { codes[i] = (long)(code_key % 9); code_key /= 9; }
            for (long color = 0; color <= 1; color++) {
                long[4] output_codes;
                long output_closed, output_diagonal;
                if (!advance_frontier(&codes[0], closed, diagonal, color, row, column,
                                      &output_codes[0], &output_closed, &output_diagonal)) continue;
                usz destination = encode_state(&output_codes[0], output_closed, output_diagonal);
                next[destination] += dp[state];
            }
        }
        for (usz state = 0; state < MAX_STATES; state++) dp[state] = next[state];
    }

    long total = 0;
    for (usz state = 0; state < MAX_STATES; state++) {
        if (dp[state] == 0) continue;
        usz code_key = state % CODE_STATES;
        long closed = (long)((state / CODE_STATES) / 3);
        bool[5] seen_black = {false};
        bool[5] seen_white = {false};
        long black_components = 0, white_components = 0;
        for (usz i = 0; i < 4; i++) {
            long code = (long)(code_key % 9); code_key /= 9;
            if (code >= 1 && code <= 4 && !seen_black[(usz)code]) { seen_black[(usz)code] = true; black_components++; }
            else if (code >= 5 && code <= 8 && !seen_white[(usz)(code - 4)]) { seen_white[(usz)(code - 4)] = true; white_components++; }
        }
        if (((closed & 1) != 0 ? black_components == 0 : black_components == 1) &&
            ((closed & 2) != 0 ? white_components == 0 : white_components == 1)) total += dp[state];
    }
    return total;
}
