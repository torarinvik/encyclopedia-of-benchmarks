module ukkonen_suffix_tree;

const int UKK_MAX_TEXT = 64;
const int UKK_MAX_SYMBOLS = UKK_MAX_TEXT + 1;
const int UKK_MAX_NODES = 2 * UKK_MAX_SYMBOLS;
const usz UKK_MAX_INPUT_LENGTH = UKK_MAX_TEXT + 2;

struct UkkonenNode {
    int start;
    int end;
    int suffix_link;
    int suffix_start;
    bool open_end;
    int[5] children;
}

fn int ukk_new_node(UkkonenNode* nodes, int* used, int start, int end,
                    bool open_end, int suffix_start) {
    if (used[0] >= UKK_MAX_NODES) return -1;
    int id = used[0]++;
    nodes[id].start = start;
    nodes[id].end = end;
    nodes[id].suffix_link = 0;
    nodes[id].suffix_start = suffix_start;
    nodes[id].open_end = open_end;
    for (int symbol = 0; symbol < 5; symbol += 1) nodes[id].children[symbol] = -1;
    return id;
}

fn int ukk_edge_end(UkkonenNode* node, int current_end) {
    return node.open_end ? current_end : node.end;
}

fn void ukk_append_token(long token, long* position, long* hash) {
    hash[0] += position[0] * token;
    position[0] += 1;
}

fn bool ukk_emit(UkkonenNode* nodes, int* text, int node_id, int current_end,
                 long* distinct, long* position, long* hash) {
    for (int symbol = 0; symbol < 5; symbol += 1) {
        int child_id = nodes[node_id].children[symbol];
        if (child_id < 0) continue;
        int end = ukk_edge_end(&nodes[child_id], current_end);
        int edge_length = end - nodes[child_id].start + 1;
        if (edge_length <= 0) return false;

        ukk_append_token(1, position, hash);
        ukk_append_token(edge_length, position, hash);
        for (int offset = 0; offset < edge_length; offset += 1) {
            int edge_symbol = text[nodes[child_id].start + offset];
            ukk_append_token(edge_symbol + 1, position, hash);
            if (edge_symbol != 4) distinct[0] += 1;
        }

        bool has_children = false;
        for (int next_symbol = 0; next_symbol < 5; next_symbol += 1) {
            if (nodes[child_id].children[next_symbol] >= 0) {
                has_children = true;
                break;
            }
        }
        if (has_children) {
            ukk_append_token(3, position, hash);
            if (!ukk_emit(nodes, text, child_id, current_end, distinct,
                          position, hash)) return false;
            ukk_append_token(4, position, hash);
        } else {
            if (nodes[child_id].suffix_start < 0) return false;
            ukk_append_token(2, position, hash);
            ukk_append_token((long)nodes[child_id].suffix_start + 1, position, hash);
        }
    }
    return true;
}

fn long ukkonen_suffix_tree(long* input, usz length) @export("ukkonen_suffix_tree") {
    if (input == null || length < 1 || length > UKK_MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > UKK_MAX_TEXT) return -1;
    int text_length = (int)input[0];
    if (length != (usz)(text_length + 1)) return -1;

    int[UKK_MAX_SYMBOLS] text = {0};
    for (int index = 0; index < text_length; index += 1) {
        if (input[index + 1] < 0 || input[index + 1] > 3) return -1;
        text[index] = (int)input[index + 1];
    }
    int total_length = text_length + 1;
    text[text_length] = 4;

    UkkonenNode[UKK_MAX_NODES] nodes = zeroed;
    int used = 0;
    int root = ukk_new_node(&nodes[0], &used, -1, -1, false, -1);
    if (root != 0) return -1;
    int active_node = root;
    int active_edge = -1;
    int active_length = 0;
    int remaining = 0;
    int leaf_end = -1;

    for (int phase = 0; phase < total_length; phase += 1) {
        leaf_end = phase;
        remaining += 1;
        int last_new_internal = -1;
        while (remaining > 0) {
            if (active_length == 0) active_edge = phase;
            int edge_symbol = text[active_edge];
            int next_id = nodes[active_node].children[edge_symbol];
            if (next_id < 0) {
                int suffix_start = phase - remaining + 1;
                int leaf = ukk_new_node(&nodes[0], &used, phase, -1, true, suffix_start);
                if (leaf < 0) return -1;
                nodes[active_node].children[edge_symbol] = leaf;
                if (last_new_internal >= 0) {
                    nodes[last_new_internal].suffix_link = active_node;
                    last_new_internal = -1;
                }
            } else {
                int next_end = ukk_edge_end(&nodes[next_id], leaf_end);
                int edge_length = next_end - nodes[next_id].start + 1;
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
                    active_length += 1;
                    break;
                }

                int split_start = nodes[next_id].start;
                int split_end = split_start + active_length - 1;
                int split = ukk_new_node(&nodes[0], &used, split_start, split_end, false, -1);
                if (split < 0) return -1;
                nodes[active_node].children[edge_symbol] = split;
                int suffix_start = phase - remaining + 1;
                int leaf = ukk_new_node(&nodes[0], &used, phase, -1, true, suffix_start);
                if (leaf < 0) return -1;
                nodes[split].children[text[phase]] = leaf;
                nodes[next_id].start += active_length;
                nodes[split].children[text[nodes[next_id].start]] = next_id;
                if (last_new_internal >= 0) nodes[last_new_internal].suffix_link = split;
                last_new_internal = split;
            }

            remaining -= 1;
            if (active_node == root && active_length > 0) {
                active_length -= 1;
                active_edge = phase - remaining + 1;
            } else if (active_node != root) {
                active_node = nodes[active_node].suffix_link;
            }
        }
    }

    long distinct = 0;
    long token_position = 1;
    long hash = 0;
    ukk_append_token(0, &token_position, &hash);
    if (!ukk_emit(&nodes[0], &text[0], root, leaf_end, &distinct,
                  &token_position, &hash)) return -1;
    ukk_append_token(4, &token_position, &hash);
    if (used > UKK_MAX_NODES || distinct > 2080 || hash > 2576350140L) return -1;
    return ((long)used << 44) | (distinct << 32) | hash;
}
