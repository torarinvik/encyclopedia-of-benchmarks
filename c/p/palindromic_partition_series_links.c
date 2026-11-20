#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 64, MAX_NODES = MAX_TEXT + 2, ALPHABET = 4, MAX_WORDS = MAX_TEXT + 1 };
typedef struct {
    int length, link, difference, series_link, series_best, series_start;
    int next[ALPHABET];
} Node;

static void initialize(Node nodes[MAX_NODES], int id, int length, int link) {
    nodes[id].length = length;
    nodes[id].link = link;
    nodes[id].difference = 0;
    nodes[id].series_link = 1;
    nodes[id].series_best = 0;
    nodes[id].series_start = 0;
    for (int c = 0; c < ALPHABET; ++c) nodes[id].next[c] = 0;
}

static int find_extendable(const Node nodes[MAX_NODES], const int text[MAX_TEXT],
                           int position, int start) {
    int node = start;
    for (;;) {
        int preceding = position - 1 - nodes[node].length;
        if (preceding >= 0 && text[preceding] == text[position]) return node;
        node = nodes[node].link;
    }
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte) output[offset + (size_t)byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t palindromic_partition_series_links(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_TEXT + 2) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT) return -1;
    int n = (int)input[0];
    if (length != (size_t)n + 1) return -1;
    int text[MAX_TEXT] = {0};
    for (int i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] >= ALPHABET) return -1;
        text[i] = (int)input[i + 1];
    }

    Node nodes[MAX_NODES];
    initialize(nodes, 0, 0, 1);
    initialize(nodes, 1, -1, 1);
    int node_count = 2, last = 0;
    int dp[MAX_TEXT + 1], predecessor[MAX_TEXT + 1];
    for (int i = 0; i <= n; ++i) { dp[i] = MAX_TEXT + 1; predecessor[i] = 0; }
    dp[0] = 0;

    for (int position = 0; position < n; ++position) {
        int end = position + 1;
        int symbol = text[position];
        int parent = find_extendable(nodes, text, position, last);
        int next = nodes[parent].next[symbol];
        if (next == 0) {
            next = node_count++;
            initialize(nodes, next, nodes[parent].length + 2, 0);
            nodes[parent].next[symbol] = next;
            if (nodes[next].length == 1) {
                nodes[next].link = 0;
            } else {
                int suffix_parent = find_extendable(nodes, text, position, nodes[parent].link);
                nodes[next].link = nodes[suffix_parent].next[symbol];
            }
            int fail = nodes[next].link;
            nodes[next].difference = nodes[next].length - nodes[fail].length;
            nodes[next].series_link = nodes[next].difference == nodes[fail].difference
                ? nodes[fail].series_link : fail;
        }
        last = next;
        int best_value = MAX_TEXT + 1, best_start = end;
        for (int node = last; nodes[node].length > 0; node = nodes[node].series_link) {
            int start = end - nodes[nodes[node].series_link].length - nodes[node].difference;
            nodes[node].series_best = dp[start];
            nodes[node].series_start = start;
            int fail = nodes[node].link;
            if (nodes[node].difference == nodes[fail].difference &&
                (nodes[fail].series_best < nodes[node].series_best ||
                 (nodes[fail].series_best == nodes[node].series_best &&
                  nodes[fail].series_start < nodes[node].series_start))) {
                nodes[node].series_best = nodes[fail].series_best;
                nodes[node].series_start = nodes[fail].series_start;
            }
            int candidate = nodes[node].series_best + 1;
            if (candidate < best_value ||
                (candidate == best_value && nodes[node].series_start < best_start)) {
                best_value = candidate;
                best_start = nodes[node].series_start;
            }
        }
        dp[end] = best_value;
        predecessor[end] = best_start;
    }

    int reverse_pieces[MAX_TEXT], piece_count = 0;
    for (int end = n; end > 0; end = predecessor[end])
        reverse_pieces[piece_count++] = end - predecessor[end];
    int64_t words[MAX_WORDS];
    size_t word_count = 0;
    words[word_count++] = piece_count;
    for (int i = piece_count - 1; i >= 0; --i) words[word_count++] = reverse_pieces[i];
    size_t bytes = word_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < word_count; ++i) put_i64(output, i * 8, words[i]);
    return (int64_t)bytes;
}
