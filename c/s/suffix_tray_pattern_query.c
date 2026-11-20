#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 12
#define MAX_PATTERN 8
#define MAX_SIGMA 4
#define MAX_SUFFIXES (MAX_TEXT + 1)
#define MAX_NODES (2 * MAX_SUFFIXES - 1)
#define MAX_OUTPUT 16

typedef struct {
    int edge_start;
    int edge_length;
    int depth;
    int leaf_start;
    int child[5];
    int leaf_count;
    int sa_left;
    int sa_right;
    int sigma;
    int kind;
    int sigma_child_count;
    int sigma_child[5];
    int child_by_symbol[MAX_SIGMA];
    int group_by_symbol[MAX_SIGMA];
    int gap_count;
    int gap_left[5];
    int gap_right[5];
    int separator;
    int only_sigma_child;
    int left_valid;
    int left_interval[2];
    int right_valid;
    int right_interval[2];
} TrayNode;

static int symbol_index(int symbol) { return symbol + 1; }

static void init_node(TrayNode *node, int start, int length, int depth, int leaf) {
    node->edge_start = start;
    node->edge_length = length;
    node->depth = depth;
    node->leaf_start = leaf;
    for (int i = 0; i < 5; ++i) {
        node->child[i] = -1;
        node->sigma_child[i] = -1;
        node->gap_left[i] = -1;
        node->gap_right[i] = -1;
    }
    node->leaf_count = 0;
    node->sa_left = 0;
    node->sa_right = -1;
    node->sigma = 0;
    node->kind = 0;
    node->sigma_child_count = 0;
    for (int i = 0; i < MAX_SIGMA; ++i) {
        node->child_by_symbol[i] = -1;
        node->group_by_symbol[i] = -1;
    }
    node->gap_count = 0;
    node->separator = -1;
    node->only_sigma_child = -1;
    node->left_valid = 0;
    node->left_interval[0] = node->left_interval[1] = -1;
    node->right_valid = 0;
    node->right_interval[0] = node->right_interval[1] = -1;
}

static int suffix_compare(const int *text, int a, int b, int length) {
    int i = 0;
    while (a + i < length && b + i < length) {
        if (text[a + i] != text[b + i]) return text[a + i] < text[b + i] ? -1 : 1;
        ++i;
    }
    if (a + i == length && b + i == length) return 0;
    return a + i == length ? -1 : 1;
}

static void build_suffix_array(const int *text, int length, int *suffixes, int *rank) {
    for (int i = 0; i < length; ++i) suffixes[i] = i;
    for (int i = 1; i < length; ++i) {
        int item = suffixes[i];
        int j = i;
        while (j > 0 && suffix_compare(text, item, suffixes[j - 1], length) < 0) {
            suffixes[j] = suffixes[j - 1];
            --j;
        }
        suffixes[j] = item;
    }
    for (int i = 0; i < length; ++i) rank[suffixes[i]] = i;
}

static void insert_suffix(TrayNode *nodes, int *node_count, const int *text,
                          int text_length, int start) {
    int current = 0;
    int position = start;
    while (position < text_length) {
        int symbol = text[position];
        int slot = symbol_index(symbol);
        int child_id = nodes[current].child[slot];
        if (child_id < 0) {
            child_id = (*node_count)++;
            int edge_length = text_length - position;
            init_node(&nodes[child_id], position, edge_length,
                      nodes[current].depth + edge_length, start);
            nodes[current].child[slot] = child_id;
            return;
        }
        int common = 0;
        while (common < nodes[child_id].edge_length &&
               position + common < text_length &&
               text[position + common] == text[nodes[child_id].edge_start + common]) {
            ++common;
        }
        if (common == nodes[child_id].edge_length) {
            position += common;
            current = child_id;
            continue;
        }
        int split_id = (*node_count)++;
        TrayNode old_child = nodes[child_id];
        init_node(&nodes[split_id], old_child.edge_start, common,
                  nodes[current].depth + common, -1);
        nodes[current].child[slot] = split_id;
        nodes[child_id].edge_start += common;
        nodes[child_id].edge_length -= common;
        nodes[split_id].child[symbol_index(text[nodes[child_id].edge_start])] = child_id;
        int new_start = position + common;
        int new_id = (*node_count)++;
        int new_length = text_length - new_start;
        init_node(&nodes[new_id], new_start, new_length,
                  nodes[split_id].depth + new_length, start);
        nodes[split_id].child[symbol_index(text[new_start])] = new_id;
        return;
    }
}

static void summarize_node(TrayNode *nodes, int node_id, const int *rank) {
    TrayNode *node = &nodes[node_id];
    if (node->leaf_start >= 0) {
        node->leaf_count = 1;
        node->sa_left = rank[node->leaf_start];
        node->sa_right = node->sa_left;
        return;
    }
    int children[5];
    int count = 0;
    for (int symbol = -1; symbol < MAX_SIGMA; ++symbol) {
        int child = node->child[symbol_index(symbol)];
        if (child >= 0) children[count++] = child;
    }
    node->leaf_count = 0;
    node->sa_left = MAX_SUFFIXES;
    node->sa_right = -1;
    for (int i = 0; i < count; ++i) {
        summarize_node(nodes, children[i], rank);
        node->leaf_count += nodes[children[i]].leaf_count;
        if (nodes[children[i]].sa_left < node->sa_left) node->sa_left = nodes[children[i]].sa_left;
        if (nodes[children[i]].sa_right > node->sa_right) node->sa_right = nodes[children[i]].sa_right;
    }
}

static void set_interval(int *valid, int interval[2], const TrayNode *nodes,
                         const int *children, int count) {
    if (count == 0) {
        *valid = 0;
        interval[0] = interval[1] = -1;
        return;
    }
    *valid = 1;
    interval[0] = nodes[children[0]].sa_left;
    interval[1] = nodes[children[count - 1]].sa_right;
}

static void build_tray(TrayNode *nodes, int node_count, int sigma, const int *text) {
    for (int id = 0; id < node_count; ++id) nodes[id].sigma = nodes[id].leaf_count >= sigma;
    for (int id = 0; id < node_count; ++id) {
        TrayNode *node = &nodes[id];
        if (!node->sigma) continue;
        int children[5];
        int child_count = 0;
        for (int symbol = -1; symbol < sigma; ++symbol) {
            int child = node->child[symbol_index(symbol)];
            if (child >= 0) children[child_count++] = child;
        }
        int sigma_children[5];
        int sig_count = 0;
        for (int i = 0; i < child_count; ++i) {
            if (nodes[children[i]].sigma) sigma_children[sig_count++] = children[i];
        }
        node->sigma_child_count = sig_count;
        for (int i = 0; i < sig_count; ++i) node->sigma_child[i] = sigma_children[i];
        if (sig_count == 0) {
            node->kind = 3;
            continue;
        }
        if (sig_count == 1) {
            node->kind = 2;
            int child = sigma_children[0];
            node->only_sigma_child = child;
            node->separator = text[nodes[child].edge_start];
            int left[5], right[5], left_count = 0, right_count = 0;
            int after = 0;
            for (int i = 0; i < child_count; ++i) {
                if (children[i] == child) { after = 1; continue; }
                if (!nodes[children[i]].sigma) {
                    if (after) right[right_count++] = children[i];
                    else left[left_count++] = children[i];
                }
            }
            set_interval(&node->left_valid, node->left_interval, nodes, left, left_count);
            set_interval(&node->right_valid, node->right_interval, nodes, right, right_count);
            continue;
        }
        node->kind = 1;
        int gaps[6][5];
        int gap_counts[6] = {0};
        int gap = 0;
        for (int i = 0; i < child_count; ++i) {
            if (nodes[children[i]].sigma) ++gap;
            else gaps[gap][gap_counts[gap]++] = children[i];
        }
        node->gap_count = sig_count + 1;
        for (int g = 0; g <= sig_count; ++g) {
            if (gap_counts[g] == 0) {
                node->gap_left[g] = node->gap_right[g] = -1;
            } else {
                node->gap_left[g] = nodes[gaps[g][0]].sa_left;
                node->gap_right[g] = nodes[gaps[g][gap_counts[g] - 1]].sa_right;
            }
        }
        for (int symbol = 0; symbol < sigma; ++symbol) {
            node->child_by_symbol[symbol] = -1;
            node->group_by_symbol[symbol] = -1;
            int found = -1;
            int preceding = 0;
            for (int i = 0; i < sig_count; ++i) {
                int first = text[nodes[sigma_children[i]].edge_start];
                if (first == symbol) { found = sigma_children[i]; break; }
                if (first < symbol) ++preceding;
            }
            if (found >= 0) node->child_by_symbol[symbol] = found;
            else if (gap_counts[preceding] > 0) node->group_by_symbol[symbol] = preceding;
        }
    }
}

static int compare_suffix_pattern(const int *text, int text_length, int suffix_start,
                                 const int *pattern, int q, int start_at, int *lcp) {
    int i = start_at;
    while (i < q && suffix_start + i < text_length) {
        if (text[suffix_start + i] != pattern[i]) {
            *lcp = i;
            return text[suffix_start + i] < pattern[i] ? -1 : 1;
        }
        ++i;
    }
    *lcp = i;
    if (i == q) return 1;
    return -1;
}

static int interval_search(const int *text, int text_length, const int *pattern, int q,
                           const int *suffixes, int lo, int hi, int known_prefix) {
    int low = lo - 1;
    int high = hi + 1;
    int low_lcp = known_prefix;
    int high_lcp = known_prefix;
    while (high - low > 1) {
        int middle = (low + high) / 2;
        int lcp = known_prefix;
        int start_at = low_lcp < high_lcp ? low_lcp : high_lcp;
        int comparison = compare_suffix_pattern(text, text_length, suffixes[middle],
                                                pattern, q, start_at, &lcp);
        if (comparison < 0) { low = middle; low_lcp = lcp; }
        else { high = middle; high_lcp = lcp; }
    }
    if (high > hi) return -1;
    int start = suffixes[high];
    if (start + q > text_length) return -1;
    for (int i = 0; i < q; ++i) if (text[start + i] != pattern[i]) return -1;
    return start;
}

static int tray_query(const int *text, int text_length, const int *pattern, int q,
                      int sigma, const int *suffixes, const TrayNode *nodes) {
    int current = 0;
    int matched = 0;
    for (;;) {
        const TrayNode *node = &nodes[current];
        if (matched == q) return suffixes[node->sa_left];
        int symbol = pattern[matched];
        if (!node->sigma || node->kind == 3) {
            return interval_search(text, text_length, pattern, q, suffixes,
                                   node->sa_left, node->sa_right, matched);
        }
        int next = -1;
        int interval_left = -1;
        int interval_right = -1;
        if (node->kind == 1) {
            if (symbol < 0 || symbol >= sigma) return -1;
            next = node->child_by_symbol[symbol];
            if (next < 0) {
                int group = node->group_by_symbol[symbol];
                if (group < 0 || node->gap_left[group] < 0) return -1;
                interval_left = node->gap_left[group];
                interval_right = node->gap_right[group];
            }
        } else {
            next = node->only_sigma_child;
            if (symbol != node->separator) {
                if (symbol < node->separator) {
                    if (!node->left_valid) return -1;
                    interval_left = node->left_interval[0];
                    interval_right = node->left_interval[1];
                } else {
                    if (!node->right_valid) return -1;
                    interval_left = node->right_interval[0];
                    interval_right = node->right_interval[1];
                }
            }
        }
        if (interval_left >= 0) {
            return interval_search(text, text_length, pattern, q, suffixes,
                                   interval_left, interval_right, matched);
        }
        if (next < 0) return -1;
        int representative = suffixes[nodes[next].sa_left];
        int edge_position = node->depth;
        while (matched < q && edge_position < nodes[next].depth) {
            if (text[representative + edge_position] != pattern[matched]) return -1;
            ++matched;
            ++edge_position;
        }
        if (matched == q) return suffixes[nodes[next].sa_left];
        if (edge_position != nodes[next].depth) return -1;
        current = next;
    }
}

static void put_i64_le(uint8_t *output, size_t position, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[position + i] = (uint8_t)(bits >> (8 * i));
}

int64_t suffix_tray_pattern_query(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 24) return -1;
    int64_t sigma64 = input[0], n64 = input[1], q64 = input[2];
    if (sigma64 < 2 || sigma64 > MAX_SIGMA || n64 < 1 || n64 > MAX_TEXT ||
        q64 < 1 || q64 > MAX_PATTERN) return -1;
    int sigma = (int)sigma64, n = (int)n64, q = (int)q64;
    if (length != (size_t)(3 + n + q)) return -1;
    int text[MAX_SUFFIXES];
    int pattern[MAX_PATTERN];
    for (int i = 0; i < n; ++i) {
        if (input[3 + i] < 0 || input[3 + i] >= sigma) return -1;
        text[i] = (int)input[3 + i];
    }
    text[n] = -1;
    for (int i = 0; i < q; ++i) {
        if (input[3 + n + i] < 0 || input[3 + n + i] >= sigma) return -1;
        pattern[i] = (int)input[3 + n + i];
    }
    if (output == NULL || capacity < MAX_OUTPUT) return -2;

    int suffixes[MAX_SUFFIXES], rank[MAX_SUFFIXES];
    build_suffix_array(text, n + 1, suffixes, rank);
    TrayNode nodes[MAX_NODES];
    for (int i = 0; i < MAX_NODES; ++i) init_node(&nodes[i], 0, 0, 0, -1);
    init_node(&nodes[0], 0, 0, 0, -1);
    int node_count = 1;
    for (int start = 0; start <= n; ++start) insert_suffix(nodes, &node_count, text, n + 1, start);
    summarize_node(nodes, 0, rank);
    build_tray(nodes, node_count, sigma, text);
    int found = tray_query(text, n + 1, pattern, q, sigma, suffixes, nodes);
    put_i64_le(output, 0, found < 0 ? 0 : 1);
    put_i64_le(output, 8, found);
    return MAX_OUTPUT;
}
