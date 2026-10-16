module crossword_puzzle_solver;
const usz MAX_WORDS = 8;
const usz MAX_WORD_LENGTH = 8;

fn bool search(long* grid, usz rows, usz cols, long* words, usz* lengths,
               usz* order, usz depth, usz word_count) {
    if (depth == word_count) return true;
    usz word = order[depth];
    usz n = lengths[word];
    for (usz row = 0; row < rows; row++) {
        for (usz col = 0; col < cols; col++) {
            for (usz direction = 0; direction < 2; direction++) {
                bool vertical = direction == 0;
                if ((vertical && row + n > rows) || (!vertical && col + n > cols)) continue;
                usz[8] cells; bool[8] added;
                bool valid = true;
                for (usz i = 0; i < n; i++) {
                    usz cell = vertical ? (row + i) * cols + col : row * cols + col + i;
                    cells[i] = cell;
                    if (grid[cell] != 0 && grid[cell] != words[word * 8 + i]) valid = false;
                }
                if (!valid) continue;
                for (usz i = 0; i < n; i++) {
                    added[i] = grid[cells[i]] == 0;
                    grid[cells[i]] = words[word * 8 + i];
                }
                if (search(grid, rows, cols, words, lengths, order, depth + 1, word_count)) return true;
                for (usz i = 0; i < n; i++) if (added[i]) grid[cells[i]] = 0;
            }
        }
    }
    return false;
}

fn long crossword_puzzle_solver(long* input, usz length, char* output, usz capacity) @export("crossword_puzzle_solver") {
    if (input == null || length < 3) return -1;
    long rv = input[0], cv = input[1], nv = input[2];
    if (rv < 1 || rv > 8 || cv < 1 || cv > 8 || nv < 0 || nv > 8) return -1;
    usz rows = (usz)rv, cols = (usz)cv, word_count = (usz)nv;
    if (length < 3 + rows * cols) return -1;
    long[64] grid = {};
    for (usz i = 0; i < rows * cols; i++) {
        long value = input[3 + i];
        if (value != 0 && value != -1 && (value < 65 || value > 90)) return -1;
        grid[i] = value;
    }
    long[64] words = {}; usz[8] lengths = {}; usz pos = 3 + rows * cols;
    for (usz w = 0; w < word_count; w++) {
        if (pos >= length || input[pos] < 1 || input[pos] > 8) return -1;
        lengths[w] = (usz)input[pos++];
        if (lengths[w] > length - pos) return -1;
        for (usz i = 0; i < lengths[w]; i++) {
            long letter = input[pos++];
            if (letter < 65 || letter > 90) return -1;
            words[w * 8 + i] = letter;
        }
    }
    if (pos != length) return -1;
    usz[8] order = {};
    for (usz i = 0; i < word_count; i++) order[i] = i;
    for (usz i = 1; i < word_count; i++) {
        usz value = order[i], j = i;
        while (j > 0 && lengths[order[j - 1]] < lengths[value]) { order[j] = order[j - 1]; j--; }
        order[j] = value;
    }
    bool solved = search(&grid[0], rows, cols, &words[0], &lengths[0], &order[0], 0, word_count);
    usz required = (1 + rows * cols) * 8;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < 1 + rows * cols; i++) {
        long value = i == 0 ? (solved ? 1 : 0) : grid[i - 1];
        ulong bits = (ulong)value;
        for (usz byte = 0; byte < 8; byte++) output[i * 8 + byte] = (char)((bits >> (8 * byte)) & 255);
    }
    return (long)required;
}
