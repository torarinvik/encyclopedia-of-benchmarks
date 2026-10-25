module rodinia_bplus_tree;

// Root separator routes point lookup into one of two sorted B+ tree leaves.
fn long rodinia_bplus_tree(long* input, usz length) @export("rodinia_bplus_tree") {
    if (input == null || length < 7 || length > 31) return -1;
    if (input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3 ||
        input[2] < 1 || input[2] > 16) return -1;
    usz left_n = (usz)input[0], right_n = (usz)input[1], query_n = (usz)input[2];
    if (length != 3 + 2 * (left_n + right_n) + query_n) return -1;
    long[2][3] keys, values;
    usz[2] counts = {left_n, right_n};
    usz cursor = 3;
    for (usz leaf = 0; leaf < 2; leaf++) {
        for (usz slot = 0; slot < counts[leaf]; slot++) {
            long key = input[cursor++], value = input[cursor++];
            if (key < -1000000 || key > 1000000 || value < 0 || value > 1000000 ||
                (slot != 0 && key <= keys[leaf][slot - 1])) return -1;
            keys[leaf][slot] = key; values[leaf][slot] = value;
        }
    }
    if (keys[0][left_n - 1] >= keys[1][0]) return -1;
    long answer = 0;
    for (usz qi = 0; qi < query_n; qi++) {
        long query = input[cursor++];
        if (query < -1000000 || query > 1000000) return -1;
        usz leaf = query < keys[1][0] ? 0 : 1;
        for (usz slot = 0; slot < counts[leaf]; slot++) {
            if (keys[leaf][slot] == query) { answer += (long)(qi + 1) * (values[leaf][slot] + 1); break; }
        }
    }
    return answer;
}
