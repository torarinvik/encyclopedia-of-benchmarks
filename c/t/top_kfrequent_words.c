#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 64
#define MAX_WORD_LENGTH 16

static int greater(const int *heap, const int *counts, int a, int b) { return counts[heap[a]] > counts[heap[b]]; }
static void sift(int *heap, const int *counts, int size, int root) {
    int best = root, left = root * 2 + 1, right = left + 1;
    if (left < size && greater(heap, counts, left, best)) best = left;
    if (right < size && greater(heap, counts, right, best)) best = right;
    if (best != root) { int t = heap[root]; heap[root] = heap[best]; heap[best] = t; sift(heap, counts, size, best); }
}

int64_t top_kfrequent_words(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 2 || n > 2 + MAX_WORDS * (MAX_WORD_LENGTH + 1)) return -1;
    if (v[0] < 0 || v[0] > MAX_WORDS || v[1] < 0 || v[1] > MAX_WORDS) return -1;
    int k = (int)v[0], words_n = (int)v[1], lens[MAX_WORDS] = {0}, counts[MAX_WORDS] = {0};
    uint8_t words[MAX_WORDS][MAX_WORD_LENGTH] = {{0}};
    int pos = 2, distinct = 0;
    for (int w = 0; w < words_n; ++w) {
        if (pos >= (int)n || v[pos] < 1 || v[pos] > MAX_WORD_LENGTH || v[pos] > (int)n - pos - 1) return -1;
        int len = (int)v[pos++];
        for (int j = 0; j < len; ++j) if (v[pos + j] < 'a' || v[pos + j] > 'z') return -1;
        int id = 0;
        for (; id < distinct; ++id) if (lens[id] == len) {
            int j = 0; while (j < len && words[id][j] == v[pos + j]) ++j;
            if (j == len) break;
        }
        if (id == distinct) { lens[id] = len; for (int j = 0; j < len; ++j) words[id][j] = (uint8_t)v[pos + j]; ++distinct; }
        ++counts[id]; pos += len;
    }
    if (pos != (int)n) return -1;
    for (int id = 0; id < distinct; ++id) {
        int rank = 0;
        for (int other = 0; other < distinct; ++other) {
            int common = lens[id] < lens[other] ? lens[id] : lens[other];
            int j = 0; while (j < common && words[other][j] == words[id][j]) ++j;
            if ((j < common && words[other][j] < words[id][j]) || (j == common && lens[other] < lens[id])) ++rank;
        }
        counts[id] = counts[id] * 65 + distinct - rank;
    }
    int heap[MAX_WORDS]; for (int i = 0; i < distinct; ++i) heap[i] = i;
    for (int i = distinct / 2 - 1; i >= 0; --i) sift(heap, counts, distinct, i);
    int limit = k < distinct ? k : distinct;
    uint8_t temp[MAX_WORDS * (MAX_WORD_LENGTH + 1) + 1]; size_t at = 0;
    for (int i = 0; i < limit; ++i) {
        int id = heap[0]; for (int j = 0; j < lens[id]; ++j) temp[at++] = words[id][j]; temp[at++] = '\n';
        heap[0] = heap[--distinct]; if (distinct) sift(heap, counts, distinct, 0);
    }
    temp[at++] = 0;
    if (!out || cap < at) return -2;
    for (size_t i = 0; i < at; ++i) out[i] = temp[i];
    return (int64_t)at;
}
