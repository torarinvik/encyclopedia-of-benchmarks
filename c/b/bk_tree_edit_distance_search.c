#include <stddef.h>
#include <stdint.h>

enum { MAX_WORDS = 16, MAX_QUERIES = 8, MAX_WORD_LENGTH = 10, MAX_RADIUS = 3 };
#define MAX_PARSEABLE_LENGTH ((size_t)28)

static int valid_word(int64_t word) {
    if (word < 0 || ((uint64_t)word >> 44) != 0) return 0;
    const int length = (int)(((uint64_t)word >> 40) & 15U);
    if (length > MAX_WORD_LENGTH) return 0;
    for (int i = 0; i < MAX_WORD_LENGTH; ++i) {
        const int symbol = (int)(((uint64_t)word >> (4 * i)) & 15U);
        if (i < length) {
            if (symbol == 0) return 0;
        } else if (symbol != 0) {
            return 0;
        }
    }
    return 1;
}

static int edit_distance(int64_t left, int64_t right) {
    const int left_length = (int)(((uint64_t)left >> 40) & 15U);
    const int right_length = (int)(((uint64_t)right >> 40) & 15U);
    int previous[MAX_WORD_LENGTH + 1] = {0};
    int current[MAX_WORD_LENGTH + 1] = {0};
    for (int j = 0; j <= right_length; ++j) previous[j] = j;
    for (int i = 1; i <= left_length; ++i) {
        current[0] = i;
        const int a = (int)(((uint64_t)left >> (4 * (i - 1))) & 15U);
        for (int j = 1; j <= right_length; ++j) {
            const int b = (int)(((uint64_t)right >> (4 * (j - 1))) & 15U);
            const int deletion = previous[j] + 1;
            const int insertion = current[j - 1] + 1;
            const int replacement = previous[j - 1] + (a != b);
            int best = deletion < insertion ? deletion : insertion;
            current[j] = best < replacement ? best : replacement;
        }
        for (int j = 0; j <= right_length; ++j) previous[j] = current[j];
    }
    return previous[right_length];
}

int64_t bk_tree_edit_distance_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t q_value = input[1];
    const int64_t radius_value = input[2];
    if (n_value < 0 || n_value > MAX_WORDS || q_value < 0 || q_value > MAX_QUERIES
            || radius_value < 0 || radius_value > MAX_RADIUS
            || length != (size_t)(3 + n_value + q_value)) return -1;
    const int n = (int)n_value;
    const int q = (int)q_value;
    const int radius = (int)radius_value;
    const int64_t *words = input + 3;
    const int64_t *queries = words + n;
    for (int i = 0; i < n + q; ++i)
        if (!valid_word(words[i])) return -1;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < i; ++j)
            if (words[i] == words[j]) return -1;

    int children[MAX_WORDS][MAX_WORD_LENGTH + 1];
    for (int i = 0; i < MAX_WORDS; ++i)
        for (int edge = 0; edge <= MAX_WORD_LENGTH; ++edge)
            children[i][edge] = -1;
    for (int node = 1; node < n; ++node) {
        int pivot = 0;
        for (;;) {
            const int edge = edit_distance(words[node], words[pivot]);
            if (children[pivot][edge] == -1) {
                children[pivot][edge] = node;
                break;
            }
            pivot = children[pivot][edge];
        }
    }

    int64_t result = 0;
    for (int query_index = 0; query_index < q; ++query_index) {
        int match_count = 0;
        int index_sum = 0;
        if (n != 0) {
            int stack[MAX_WORDS];
            int top = 0;
            stack[top++] = 0;
            while (top != 0) {
                const int node = stack[--top];
                const int distance = edit_distance(queries[query_index], words[node]);
                if (distance <= radius) {
                    ++match_count;
                    index_sum += node;
                }
                int low = distance - radius;
                if (low < 0) low = 0;
                int high = distance + radius;
                if (high > MAX_WORD_LENGTH) high = MAX_WORD_LENGTH;
                for (int edge = low; edge <= high; ++edge)
                    if (children[node][edge] != -1)
                        stack[top++] = children[node][edge];
            }
        }
        result += (int64_t)(query_index + 1) * (17 * match_count + index_sum);
    }
    return result;
}
