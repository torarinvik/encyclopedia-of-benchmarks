#include <stddef.h>
#include <stdint.h>

#define UKK_MAX_TEXT 64
#define UKK_MAX_SYMBOLS (UKK_MAX_TEXT + 1)
#define UKK_MAX_NODES (2 * UKK_MAX_SYMBOLS)
#define UKK_MAX_INPUT_LENGTH (UKK_MAX_TEXT + 2)

typedef struct {
    int start;
    int end;
    int suffix_link;
    int suffix_start;
    int open_end;
    int children[5];
} UkkonenNode;

static int ukk_new_node(UkkonenNode *nodes, int *used, int start, int end,
                        int open_end, int suffix_start) {
    if (*used >= UKK_MAX_NODES) return -1;
    const int id = (*used)++;
    nodes[id].start = start;
    nodes[id].end = end;
    nodes[id].suffix_link = 0;
    nodes[id].suffix_start = suffix_start;
    nodes[id].open_end = open_end;
    for (int symbol = 0; symbol < 5; ++symbol) nodes[id].children[symbol] = -1;
    return id;
}

static int ukk_edge_end(const UkkonenNode *node, int current_end) {
    return node->open_end ? current_end : node->end;
}

static void ukk_append_token(int64_t token, int64_t *position, int64_t *hash) {
    *hash += *position * token;
    ++*position;
}

static int ukk_emit(const UkkonenNode *nodes, const int *text, int node_id,
                    int current_end, int64_t *distinct, int64_t *position,
                    int64_t *hash) {
    for (int symbol = 0; symbol < 5; ++symbol) {
        const int child_id = nodes[node_id].children[symbol];
        if (child_id < 0) continue;
        const UkkonenNode *child = &nodes[child_id];
        const int end = ukk_edge_end(child, current_end);
        const int edge_length = end - child->start + 1;
        if (edge_length <= 0) return 0;

        ukk_append_token(1, position, hash);
        ukk_append_token(edge_length, position, hash);
        for (int offset = 0; offset < edge_length; ++offset) {
            const int edge_symbol = text[child->start + offset];
            ukk_append_token(edge_symbol + 1, position, hash);
            if (edge_symbol != 4) ++*distinct;
        }

        int has_children = 0;
        for (int next_symbol = 0; next_symbol < 5; ++next_symbol) {
            if (child->children[next_symbol] >= 0) {
                has_children = 1;
                break;
            }
        }
        if (has_children) {
            ukk_append_token(3, position, hash);
            if (!ukk_emit(nodes, text, child_id, current_end, distinct,
                          position, hash)) return 0;
            ukk_append_token(4, position, hash);
        } else {
            if (child->suffix_start < 0) return 0;
            ukk_append_token(2, position, hash);
            ukk_append_token((int64_t)child->suffix_start + 1, position, hash);
        }
    }
    return 1;
}

int64_t ukkonen_suffix_tree(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > UKK_MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > UKK_MAX_TEXT) return -1;
    const int text_length = (int)input[0];
    if (length != (size_t)(text_length + 1)) return -1;

    int text[UKK_MAX_SYMBOLS] = {0};
    for (int i = 0; i < text_length; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > 3) return -1;
        text[i] = (int)input[i + 1];
    }
    const int total_length = text_length + 1;
    text[text_length] = 4;

    UkkonenNode nodes[UKK_MAX_NODES] = {0};
    int used = 0;
    const int root = ukk_new_node(nodes, &used, -1, -1, 0, -1);
    if (root != 0) return -1;

    int active_node = root;
    int active_edge = -1;
    int active_length = 0;
    int remaining = 0;
    int leaf_end = -1;

    for (int phase = 0; phase < total_length; ++phase) {
        leaf_end = phase;
        ++remaining;
        int last_new_internal = -1;
        while (remaining > 0) {
            if (active_length == 0) active_edge = phase;
            const int edge_symbol = text[active_edge];
            const int next_id = nodes[active_node].children[edge_symbol];

            if (next_id < 0) {
                const int suffix_start = phase - remaining + 1;
                const int leaf = ukk_new_node(nodes, &used, phase, -1, 1,
                                              suffix_start);
                if (leaf < 0) return -1;
                nodes[active_node].children[edge_symbol] = leaf;
                if (last_new_internal >= 0) {
                    nodes[last_new_internal].suffix_link = active_node;
                    last_new_internal = -1;
                }
            } else {
                const int next_end = ukk_edge_end(&nodes[next_id], leaf_end);
                const int edge_length = next_end - nodes[next_id].start + 1;
                if (active_length >= edge_length) {
                    active_edge += edge_length;
                    active_length -= edge_length;
                    active_node = next_id;
                    continue;
                }

                if (text[nodes[next_id].start + active_length] == text[phase]) {
                    if (last_new_internal >= 0) {
                        nodes[last_new_internal].suffix_link = active_node;
                        last_new_internal = -1;
                    }
                    ++active_length;
                    break;
                }

                const int split_start = nodes[next_id].start;
                const int split_end = split_start + active_length - 1;
                const int split = ukk_new_node(nodes, &used, split_start, split_end,
                                               0, -1);
                if (split < 0) return -1;
                nodes[active_node].children[edge_symbol] = split;
                const int suffix_start = phase - remaining + 1;
                const int leaf = ukk_new_node(nodes, &used, phase, -1, 1,
                                              suffix_start);
                if (leaf < 0) return -1;
                nodes[split].children[text[phase]] = leaf;
                nodes[next_id].start += active_length;
                nodes[split].children[text[nodes[next_id].start]] = next_id;
                if (last_new_internal >= 0)
                    nodes[last_new_internal].suffix_link = split;
                last_new_internal = split;
            }

            --remaining;
            if (active_node == root && active_length > 0) {
                --active_length;
                active_edge = phase - remaining + 1;
            } else if (active_node != root) {
                active_node = nodes[active_node].suffix_link;
            }
        }
    }

    int64_t distinct = 0;
    int64_t token_position = 1;
    int64_t hash = 0;
    ukk_append_token(0, &token_position, &hash);
    if (!ukk_emit(nodes, text, root, leaf_end, &distinct, &token_position, &hash)) return -1;
    ukk_append_token(4, &token_position, &hash);
    if (used > UKK_MAX_NODES || distinct > 2080 || hash > INT64_C(2576350140)) return -1;
    return ((int64_t)used << 44) | (distinct << 32) | hash;
}
