module palindromic_partition_series_links;
import "core:c";

const int MAX_TEXT = 64;
const int MAX_NODES = MAX_TEXT + 2;
const int ALPHABET = 4;

struct Node {
    int length;
    int link;
    int difference;
    int series_link;
    int series_best;
    int series_start;
    int[4] next;
}

fn void initialize(Node* nodes, int id, int length, int link) {
    nodes[id].length = length;
    nodes[id].link = link;
    nodes[id].difference = 0;
    nodes[id].series_link = 1;
    nodes[id].series_best = 0;
    nodes[id].series_start = 0;
    for (int c = 0; c < ALPHABET; c++) nodes[id].next[c] = 0;
}

fn int find_extendable(Node* nodes, int* text, int position, int start) {
    int node = start;
    while (true) {
        int preceding = position - 1 - nodes[node].length;
        if (preceding >= 0 && text[preceding] == text[position]) return node;
        node = nodes[node].link;
    }
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long palindromic_partition_series_links(long* input, usz length, char* output, usz capacity)
    @export("palindromic_partition_series_links") {
    if (input == null || length < 1 || length > MAX_TEXT + 2) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT) return -1;
    int n = (int)input[0];
    if (length != (usz)(n + 1)) return -1;
    int[MAX_TEXT] text;
    for (int i = 0; i < n; i++) {
        if (input[i + 1] < 0 || input[i + 1] >= ALPHABET) return -1;
        text[i] = (int)input[i + 1];
    }

    Node[MAX_NODES] nodes;
    initialize(&nodes[0], 0, 0, 1);
    initialize(&nodes[0], 1, -1, 1);
    int node_count = 2;
    int last = 0;
    int[MAX_TEXT + 1] dp;
    int[MAX_TEXT + 1] predecessor;
    for (int i = 0; i <= n; i++) { dp[i] = MAX_TEXT + 1; predecessor[i] = 0; }
    dp[0] = 0;

    for (int position = 0; position < n; position++) {
        int end = position + 1;
        int symbol = text[position];
        int parent = find_extendable(&nodes[0], &text[0], position, last);
        int next = nodes[parent].next[symbol];
        if (next == 0) {
            next = node_count++;
            initialize(&nodes[0], next, nodes[parent].length + 2, 0);
            nodes[parent].next[symbol] = next;
            if (nodes[next].length == 1) {
                nodes[next].link = 0;
            } else {
                int suffix_parent = find_extendable(&nodes[0], &text[0], position, nodes[parent].link);
                nodes[next].link = nodes[suffix_parent].next[symbol];
            }
            int fail = nodes[next].link;
            nodes[next].difference = nodes[next].length - nodes[fail].length;
            nodes[next].series_link = nodes[next].difference == nodes[fail].difference
                ? nodes[fail].series_link : fail;
        }
        last = next;
        int best_value = MAX_TEXT + 1;
        int best_start = end;
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

    int[MAX_TEXT] reverse_pieces;
    int piece_count = 0;
    for (int end = n; end > 0; end = predecessor[end])
        reverse_pieces[piece_count++] = end - predecessor[end];
    long[MAX_TEXT + 1] words;
    usz word_count = 0;
    words[word_count++] = (long)piece_count;
    for (int i = piece_count - 1; i >= 0; i--) words[word_count++] = (long)reverse_pieces[i];
    usz bytes = word_count * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < word_count; i++) put_i64(output + i * 8, 0, words[i]);
    return (long)bytes;
}
