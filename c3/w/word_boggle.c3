module word_boggle;

const int MAX_NODES = 481;
const int ALPHABET = 52;
fn int char_index(long ch) { if (ch >= 65 && ch <= 90) return (int)(ch - 65); return (int)(ch - 97 + 26); }
fn bool valid_char(long ch) { return (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122); }
fn void search(long* board, usz rows, usz cols, usz position, int node, ushort* children,
               int* terminal, bool* visited, bool* found) {
    visited[position] = true;
    if (terminal[node] >= 0) found[terminal[node]] = true;
    int row = (int)(position / cols); int col = (int)(position % cols);
    for (int dr = -1; dr <= 1; dr++) for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        int nr = row + dr; int nc = col + dc;
        if (nr < 0 || nc < 0 || nr >= (int)rows || nc >= (int)cols) continue;
        usz next = (usz)nr * cols + (usz)nc;
        if (visited[next]) continue;
        int child = (int)children[node * ALPHABET + char_index(board[next])];
        if (child > 0) search(board, rows, cols, next, child - 1, children, terminal, visited, found);
    }
    visited[position] = false;
}
fn bool word_less(long* words, int* lengths, int a, int b) {
    usz n = (usz)(lengths[a] < lengths[b] ? lengths[a] : lengths[b]);
    for (usz i = 0; i < n; i++) { long x = words[(usz)a * 15 + i]; long y = words[(usz)b * 15 + i]; if (x != y) return x < y; }
    return lengths[a] < lengths[b];
}
fn long word_boggle(long* input, usz length, char* output, usz capacity) @export("word_boggle") {
    if (input == null || length < 3 || length > 551) return -1;
    long rr = input[0]; long cc = input[1];
    if (rr < 1 || rr > 6 || cc < 1 || cc > 6) return -1;
    usz rows = (usz)rr; usz cols = (usz)cc; usz cells = rows * cols; usz dictionary_at = 2 + cells;
    if (length <= dictionary_at) return -1;
    long count_raw = input[dictionary_at];
    if (count_raw < 0 || count_raw > 32) return -1;
    usz count = (usz)count_raw;
    for (usz i = 0; i < cells; i++) if (!valid_char(input[2 + i])) return -1;
    long[480] words = {}; int[32] word_lengths = {}; int unique = 0; usz at = dictionary_at + 1;
    for (usz k = 0; k < count; k++) {
        if (at >= length) return -1;
        long lr = input[at++]; if (lr < 1 || lr > 15 || length - at < (usz)lr) return -1;
        bool duplicate = false;
        for (int w = 0; w < unique; w++) if (word_lengths[w] == (int)lr) {
            bool same = true; for (usz j = 0; j < (usz)lr; j++) if (words[w * 15 + (int)j] != input[at + j]) same = false;
            if (same) duplicate = true;
        }
        for (usz j = 0; j < (usz)lr; j++) if (!valid_char(input[at + j])) return -1;
        if (!duplicate) { word_lengths[unique] = (int)lr; for (usz j = 0; j < (usz)lr; j++) words[unique * 15 + (int)j] = input[at + j]; unique++; }
        at += (usz)lr;
    }
    if (at != length) return -1;
    ushort[MAX_NODES * ALPHABET] children = {};
    int[MAX_NODES] terminal; for (int i = 0; i < MAX_NODES; i++) terminal[i] = -1;
    int nodes = 1;
    for (int w = 0; w < unique; w++) {
        int node = 0;
        for (int j = 0; j < word_lengths[w]; j++) {
            int edge = char_index(words[w * 15 + j]); int slot = node * ALPHABET + edge;
            if (children[slot] == 0) { children[slot] = (ushort)(nodes + 1); nodes++; }
            node = (int)children[slot] - 1;
        }
        terminal[node] = w;
    }
    bool[32] found = {}; bool[36] visited = {};
    for (usz p = 0; p < cells; p++) {
        int node = (int)children[char_index(input[2 + p])];
        if (node > 0) search(input + 2, rows, cols, p, node - 1, &children[0], &terminal[0], &visited[0], &found[0]);
    }
    int[32] order; int found_count = 0; usz output_size = 0;
    for (int w = 0; w < unique; w++) if (found[w]) { order[found_count++] = w; output_size += (usz)word_lengths[w] + 1; }
    for (int i = 1; i < found_count; i++) { int value = order[i]; int j = i; while (j > 0 && word_less(&words[0], &word_lengths[0], value, order[j-1])) { order[j] = order[j-1]; j--; } order[j] = value; }
    if (capacity < output_size || (output == null && output_size > 0)) return -2;
    usz pos = 0;
    for (int k = 0; k < found_count; k++) { int w = order[k]; for (int j = 0; j < word_lengths[w]; j++) { output[pos] = (char)words[w * 15 + j]; pos++; } output[pos] = 0; pos++; }
    return (long)output_size;
}
