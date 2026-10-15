module word_search_generator;

const long MAX_DIMENSION = 32;
const long MAX_WORDS = 96;
const long MAX_WORD_LENGTH = 32;
const long MAX_INPUT_VALUES = 4096;
const ulong RNG_MODULUS = 2147483647ul;

fn ulong next_random(ulong* state) {
    state[0] = (state[0] * 48271ul) % RNG_MODULUS;
    return state[0];
}

fn void shuffle(usz* items, usz count, ulong* state) {
    for (usz remaining = count; remaining > 1; remaining--) {
        usz other = (usz)(next_random(state) % (ulong)remaining);
        usz temporary = items[remaining - 1];
        items[remaining - 1] = items[other];
        items[other] = temporary;
    }
}

fn bool is_ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn long word_search_generator(long* values, usz length, char* output,
                              usz output_capacity) @export("word_search_generator") {
    if (values == null || length < 4 || length > MAX_INPUT_VALUES) return -1;
    long width_value = values[0];
    long height_value = values[1];
    long seed_value = values[2];
    long word_count_value = values[3];
    if (width_value < 1 || width_value > MAX_DIMENSION ||
        height_value < 1 || height_value > MAX_DIMENSION ||
        seed_value < 1 || seed_value >= (long)RNG_MODULUS ||
        word_count_value < 0 || word_count_value > MAX_WORDS) return -1;
    usz width = (usz)width_value;
    usz height = (usz)height_value;
    usz word_count = (usz)word_count_value;

    usz position = 4;
    for (usz word = 0; word < word_count; word++) {
        if (position >= length) return -1;
        long word_length_value = values[position++];
        if (word_length_value < 1 || word_length_value > MAX_WORD_LENGTH ||
            (ulong)word_length_value > (ulong)(length - position)) return -1;
        usz word_length = (usz)word_length_value;
        for (usz offset = 0; offset < word_length; offset++) {
            if (!is_ascii_letter(values[position + offset])) return -1;
        }
        position += word_length;
    }
    if (position != length) return -1;

    usz cells = width * height;
    if (output == null || output_capacity < cells) return -2;
    char[1024] board;
    for (usz index = 0; index < cells; index++) board[index] = 0;
    int[8] row_delta = {-1, -1, 0, 1, 1, 1, 0, -1};
    int[8] column_delta = {0, 1, 1, 1, 0, -1, -1, -1};
    ulong state = (ulong)seed_value;
    position = 4;

    for (usz word = 0; word < word_count; word++) {
        usz word_length = (usz)values[position++];
        usz word_start = position;
        position += word_length;
        usz[MAX_DIMENSION] rows;
        usz[MAX_DIMENSION] columns;
        for (usz row = 0; row < height; row++) rows[row] = row;
        for (usz column = 0; column < width; column++) columns[column] = column;
        shuffle(&rows[0], height, &state);
        shuffle(&columns[0], width, &state);
        usz direction = (usz)(next_random(&state) % 8ul);
        bool placed = false;
        for (usz row_index = 0; row_index < height && !placed; row_index++) {
            for (usz column_index = 0; column_index < width && !placed; column_index++) {
                int row = (int)rows[row_index];
                int column = (int)columns[column_index];
                int last_row = row + ((int)word_length - 1) * row_delta[direction];
                int last_column = column + ((int)word_length - 1) * column_delta[direction];
                if (last_row < 0 || last_row >= (int)height ||
                    last_column < 0 || last_column >= (int)width) continue;
                bool available = true;
                for (usz offset = 0; offset < word_length; offset++) {
                    int current_row = row + (int)offset * row_delta[direction];
                    int current_column = column + (int)offset * column_delta[direction];
                    if (board[(usz)current_row * width + (usz)current_column] != 0) {
                        available = false;
                        break;
                    }
                }
                if (!available) continue;
                for (usz offset = 0; offset < word_length; offset++) {
                    int current_row = row + (int)offset * row_delta[direction];
                    int current_column = column + (int)offset * column_delta[direction];
                    board[(usz)current_row * width + (usz)current_column] = (char)values[word_start + offset];
                }
                placed = true;
            }
        }
    }
    for (usz index = 0; index < cells; index++) output[index] = board[index];
    return (long)cells;
}
