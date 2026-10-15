module word_search;

const usz MAX_CELLS = 36;
const usz MAX_WORD_LENGTH = 15;

fn bool is_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn bool word_search_visit(long* input, usz columns, usz rows, usz word_start,
        usz word_length, usz position, usz word_index, bool* visited) {
    if (visited[position] || input[2 + position] != input[word_start + word_index]) return false;
    visited[position] = true;
    if (word_index + 1 == word_length) {
        visited[position] = false;
        return true;
    }
    usz row = position / columns;
    usz column = position % columns;
    bool found = false;
    if (row > 0) {
        found = word_search_visit(input, columns, rows, word_start, word_length,
                                  position - columns, word_index + 1, visited);
    }
    if (!found && row + 1 < rows) {
        found = word_search_visit(input, columns, rows, word_start, word_length,
                                  position + columns, word_index + 1, visited);
    }
    if (!found && column > 0) {
        found = word_search_visit(input, columns, rows, word_start, word_length,
                                  position - 1, word_index + 1, visited);
    }
    if (!found && column + 1 < columns) {
        found = word_search_visit(input, columns, rows, word_start, word_length,
                                  position + 1, word_index + 1, visited);
    }
    visited[position] = false;
    return found;
}

fn long word_search(long* input, usz length) @export("word_search") {
    if (input == null || length < 5 || input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6) {
        return -1;
    }
    usz rows = (usz)input[0];
    usz columns = (usz)input[1];
    usz cells = rows * columns;
    usz word_length_index = 2 + cells;
    if (length <= word_length_index) return -1;
    long word_length_value = input[word_length_index];
    if (word_length_value < 1 || word_length_value > (long)MAX_WORD_LENGTH ||
        length != word_length_index + 1 + (usz)word_length_value) return -1;
    usz word_length = (usz)word_length_value;
    for (usz index = 0; index < cells; index++) {
        if (!is_letter(input[2 + index])) return -1;
    }
    usz word_start = word_length_index + 1;
    for (usz index = 0; index < word_length; index++) {
        if (!is_letter(input[word_start + index])) return -1;
    }
    if (word_length > cells) return 0;
    bool[MAX_CELLS] visited;
    for (usz index = 0; index < MAX_CELLS; index++) visited[index] = false;
    for (usz position = 0; position < cells; position++) {
        if (word_search_visit(input, columns, rows, word_start, word_length,
                              position, 0, &visited[0])) return 1;
    }
    return 0;
}
