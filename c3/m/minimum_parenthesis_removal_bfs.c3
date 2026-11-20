module minimum_parenthesis_removal_bfs;

const usz MAX_TEXT = 16;
const usz MAX_PARENS = 8;
const usz MAX_ROWS = 256;
const usz MAX_OUTPUT = 4354;

fn usz bit_count(uint value) { usz n = 0; while (value != 0) { n += value & 1; value >>= 1; } return n; }
fn bool is_balanced(uchar* text, usz n) {
    int depth = 0;
    for (usz i = 0; i < n; i++) { if (text[i] == '(') depth++; else if (text[i] == ')') { depth--; if (depth < 0) return false; } }
    return depth == 0;
}
fn bool less_row(uchar* a, usz al, uchar* b, usz bl) {
    usz common = al < bl ? al : bl;
    for (usz i = 0; i < common; i++) { if (a[i] != b[i]) return a[i] < b[i]; }
    return al < bl;
}
fn bool equal_row(uchar* a, usz al, uchar* b, usz bl) {
    if (al != bl) return false;
    for (usz i = 0; i < al; i++) if (a[i] != b[i]) return false;
    return true;
}

fn long minimum_parenthesis_removal_bfs(long* input, usz length, uchar* output, usz capacity) @export("minimum_parenthesis_removal_bfs") {
    if (input == null || length < 1 || length > MAX_TEXT + 1) return -1;
    long n_arg = input[0]; if (n_arg < 0 || n_arg > MAX_TEXT || length != (usz)n_arg + 1) return -1;
    usz n = (usz)n_arg;
    uchar[MAX_TEXT] text = zeroed; uchar[MAX_PARENS] positions = zeroed; usz p = 0;
    for (usz i = 0; i < n; i++) {
        long value = input[i + 1];
        if (value == '(' || value == ')') { if (p == MAX_PARENS) return -1; positions[p++] = (uchar)i; }
        else if (value < 'a' || value > 'z') return -1;
        text[i] = (uchar)value;
    }
    uchar[MAX_ROWS][MAX_TEXT] rows = zeroed; uchar[MAX_ROWS] sizes = zeroed; usz count = 0;
    uint states = 1 << p;
    for (usz deletions = 0; deletions <= p; deletions++) {
        for (uint mask = 0; mask < states; mask++) {
            if (bit_count(mask) != deletions) continue;
            uchar[MAX_TEXT] candidate = zeroed; usz used = 0; usz ordinal = 0;
            for (usz i = 0; i < n; i++) {
                bool at_paren = ordinal < p && positions[ordinal] == i;
                bool remove = at_paren && (mask & (1 << ordinal)) != 0;
                if (at_paren) ordinal++;
                if (!remove) candidate[used++] = text[i];
            }
            if (!is_balanced(&candidate[0], used)) continue;
            bool duplicate = false;
            for (usz r = 0; r < count; r++) if (equal_row(&rows[r][0], sizes[r], &candidate[0], used)) duplicate = true;
            if (!duplicate) { for (usz j = 0; j < used; j++) rows[count][j] = candidate[j]; sizes[count++] = (uchar)used; }
        }
        if (count != 0) break;
    }
    if (count == 0) { rows[0][0] = 0; sizes[0] = 0; count = 1; }
    for (usz i = 1; i < count; i++) {
        uchar[MAX_TEXT] key = zeroed; usz key_len = sizes[i]; for (usz j = 0; j < key_len; j++) key[j] = rows[i][j];
        usz j = i;
        while (j > 0 && less_row(&key[0], key_len, &rows[j - 1][0], sizes[j - 1])) {
            for (usz k = 0; k < sizes[j - 1]; k++) rows[j][k] = rows[j - 1][k]; sizes[j] = sizes[j - 1]; j--;
        }
        for (usz k = 0; k < key_len; k++) rows[j][k] = key[k]; sizes[j] = (uchar)key_len;
    }
    usz needed = 2; for (usz r = 0; r < count; r++) needed += 1 + sizes[r];
    if (needed > MAX_OUTPUT) return -1;
    if (output == null || capacity < needed) return -2;
    output[0] = (uchar)count; output[1] = (uchar)(count >> 8); usz pos = 2;
    for (usz r = 0; r < count; r++) { output[pos++] = sizes[r]; for (usz j = 0; j < sizes[r]; j++) output[pos++] = rows[r][j]; }
    return (long)pos;
}
