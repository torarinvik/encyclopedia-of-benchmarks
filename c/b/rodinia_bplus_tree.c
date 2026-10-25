/* Rodinia B+ tree point-search profile; see package README and LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

#define BPT_MAX_LEAF 3
#define BPT_MAX_QUERIES 16

int64_t rodinia_bplus_tree(const int64_t *input, size_t length) {
    if (input == NULL || length < 7 || length > 31) return -1;
    const int64_t left_n_value = input[0], right_n_value = input[1], query_n_value = input[2];
    if (left_n_value < 1 || left_n_value > BPT_MAX_LEAF ||
        right_n_value < 1 || right_n_value > BPT_MAX_LEAF ||
        query_n_value < 1 || query_n_value > BPT_MAX_QUERIES) return -1;
    const size_t left_n = (size_t)left_n_value, right_n = (size_t)right_n_value;
    const size_t query_n = (size_t)query_n_value;
    if (length != 3 + 2 * (left_n + right_n) + query_n) return -1;
    int64_t keys[2][BPT_MAX_LEAF], values[2][BPT_MAX_LEAF];
    const size_t counts[2] = {left_n, right_n};
    size_t cursor = 3;
    for (size_t leaf = 0; leaf < 2; ++leaf) {
        for (size_t slot = 0; slot < counts[leaf]; ++slot) {
            const int64_t key = input[cursor++], value = input[cursor++];
            if (key < -1000000 || key > 1000000 || value < 0 || value > 1000000 ||
                (slot != 0 && key <= keys[leaf][slot - 1])) return -1;
            keys[leaf][slot] = key;
            values[leaf][slot] = value;
        }
    }
    if (keys[0][left_n - 1] >= keys[1][0]) return -1;
    int64_t answer = 0;
    for (size_t query_index = 0; query_index < query_n; ++query_index) {
        const int64_t query = input[cursor++];
        if (query < -1000000 || query > 1000000) return -1;
        const size_t leaf = query < keys[1][0] ? 0 : 1;
        for (size_t slot = 0; slot < counts[leaf]; ++slot) {
            if (keys[leaf][slot] == query) {
                answer += (int64_t)(query_index + 1) * (values[leaf][slot] + 1);
                break;
            }
        }
    }
    return answer;
}
