module suffix_tray_pattern_query;

const int MAX_TEXT = 12;
const int MAX_PATTERN = 8;
const int MAX_SIGMA = 4;
const int MAX_SUFFIXES = MAX_TEXT + 1;
const int MAX_NODES = 2 * MAX_SUFFIXES - 1;
const usz MAX_OUTPUT = 16;

struct TrayNode {
    int edge_start;
    int edge_length;
    int depth;
    int leaf_start;
    int[5] child;
    int leaf_count;
    int sa_left;
    int sa_right;
    bool sigma;
    int kind;
    int sigma_child_count;
    int[5] sigma_child;
    int[MAX_SIGMA] child_by_symbol;
    int[MAX_SIGMA] group_by_symbol;
    int gap_count;
    int[5] gap_left;
    int[5] gap_right;
    int separator;
    int only_sigma_child;
    bool left_valid;
    int[2] left_interval;
    bool right_valid;
    int[2] right_interval;
}

fn int slot(int symbol) { return symbol + 1; }

fn void init_node(TrayNode* node, int start, int length, int depth, int leaf) {
    node.edge_start = start; node.edge_length = length; node.depth = depth; node.leaf_start = leaf;
    for (int i = 0; i < 5; i++) {
        node.child[i] = -1; node.sigma_child[i] = -1;
        node.gap_left[i] = -1; node.gap_right[i] = -1;
    }
    node.leaf_count = 0; node.sa_left = 0; node.sa_right = -1;
    node.sigma = false; node.kind = 0; node.sigma_child_count = 0;
    for (int i = 0; i < MAX_SIGMA; i++) {
        node.child_by_symbol[i] = -1; node.group_by_symbol[i] = -1;
    }
    node.gap_count = 0; node.separator = -1; node.only_sigma_child = -1;
    node.left_valid = false; node.left_interval[0] = -1; node.left_interval[1] = -1;
    node.right_valid = false; node.right_interval[0] = -1; node.right_interval[1] = -1;
}

fn int suffix_compare(int* text, int a, int b, int length) {
    int i = 0;
    while (a + i < length && b + i < length) {
        if (text[a + i] != text[b + i]) return text[a + i] < text[b + i] ? -1 : 1;
        i++;
    }
    if (a + i == length && b + i == length) return 0;
    return a + i == length ? -1 : 1;
}

fn void build_suffix_array(int* text, int length, int* suffixes, int* rank) {
    for (int i = 0; i < length; i++) suffixes[i] = i;
    for (int i = 1; i < length; i++) {
        int item = suffixes[i], j = i;
        while (j > 0 && suffix_compare(text, item, suffixes[j - 1], length) < 0) {
            suffixes[j] = suffixes[j - 1]; j--;
        }
        suffixes[j] = item;
    }
    for (int i = 0; i < length; i++) rank[suffixes[i]] = i;
}

fn void insert_suffix(TrayNode* nodes, int* node_count, int* text,
                      int text_length, int start) {
    int current = 0, position = start;
    while (position < text_length) {
        int symbol = text[position], child_id = nodes[current].child[slot(symbol)];
        if (child_id < 0) {
            child_id = *node_count; *node_count += 1;
            int edge_length = text_length - position;
            init_node(&nodes[child_id], position, edge_length,
                      nodes[current].depth + edge_length, start);
            nodes[current].child[slot(symbol)] = child_id;
            return;
        }
        int common = 0;
        while (common < nodes[child_id].edge_length && position + common < text_length &&
               text[position + common] == text[nodes[child_id].edge_start + common]) common++;
        if (common == nodes[child_id].edge_length) {
            position += common; current = child_id; continue;
        }
        int split_id = *node_count; *node_count += 1;
        int old_start = nodes[child_id].edge_start;
        init_node(&nodes[split_id], old_start, common, nodes[current].depth + common, -1);
        nodes[current].child[slot(symbol)] = split_id;
        nodes[child_id].edge_start += common;
        nodes[child_id].edge_length -= common;
        nodes[split_id].child[slot(text[nodes[child_id].edge_start])] = child_id;
        int new_start = position + common, new_id = *node_count; *node_count += 1;
        int new_length = text_length - new_start;
        init_node(&nodes[new_id], new_start, new_length,
                  nodes[split_id].depth + new_length, start);
        nodes[split_id].child[slot(text[new_start])] = new_id;
        return;
    }
}

fn void summarize_node(TrayNode* nodes, int node_id, int* rank) {
    if (nodes[node_id].leaf_start >= 0) {
        nodes[node_id].leaf_count = 1;
        nodes[node_id].sa_left = rank[nodes[node_id].leaf_start];
        nodes[node_id].sa_right = nodes[node_id].sa_left;
        return;
    }
    int[5] children = zeroed; int count = 0;
    for (int symbol = -1; symbol < MAX_SIGMA; symbol++) {
        int child = nodes[node_id].child[slot(symbol)];
        if (child >= 0) children[count++] = child;
    }
    nodes[node_id].leaf_count = 0; nodes[node_id].sa_left = MAX_SUFFIXES; nodes[node_id].sa_right = -1;
    for (int i = 0; i < count; i++) {
        int child = children[i]; summarize_node(nodes, child, rank);
        nodes[node_id].leaf_count += nodes[child].leaf_count;
        if (nodes[child].sa_left < nodes[node_id].sa_left) nodes[node_id].sa_left = nodes[child].sa_left;
        if (nodes[child].sa_right > nodes[node_id].sa_right) nodes[node_id].sa_right = nodes[child].sa_right;
    }
}

fn void set_interval(bool* valid, int* interval, TrayNode* nodes, int* children, int count) {
    if (count == 0) { *valid = false; interval[0] = -1; interval[1] = -1; return; }
    *valid = true; interval[0] = nodes[children[0]].sa_left;
    interval[1] = nodes[children[count - 1]].sa_right;
}

fn void build_tray(TrayNode* nodes, int node_count, int sigma, int* text) {
    for (int id = 0; id < node_count; id++) nodes[id].sigma = nodes[id].leaf_count >= sigma;
    for (int id = 0; id < node_count; id++) {
        if (!nodes[id].sigma) continue;
        int[5] children = zeroed; int child_count = 0;
        for (int symbol = -1; symbol < sigma; symbol++) {
            int child = nodes[id].child[slot(symbol)]; if (child >= 0) children[child_count++] = child;
        }
        int[5] sigma_children = zeroed; int sig_count = 0;
        for (int i = 0; i < child_count; i++) if (nodes[children[i]].sigma) sigma_children[sig_count++] = children[i];
        nodes[id].sigma_child_count = sig_count;
        for (int i = 0; i < sig_count; i++) nodes[id].sigma_child[i] = sigma_children[i];
        if (sig_count == 0) { nodes[id].kind = 3; continue; }
        if (sig_count == 1) {
            nodes[id].kind = 2; int child = sigma_children[0];
            nodes[id].only_sigma_child = child; nodes[id].separator = text[nodes[child].edge_start];
            int[5] left = zeroed; int[5] right = zeroed;
            int left_count = 0, right_count = 0; bool after = false;
            for (int i = 0; i < child_count; i++) {
                int item = children[i]; if (item == child) { after = true; continue; }
                if (!nodes[item].sigma) { if (after) right[right_count++] = item; else left[left_count++] = item; }
            }
            set_interval(&nodes[id].left_valid, nodes[id].left_interval, nodes, left, left_count);
            set_interval(&nodes[id].right_valid, nodes[id].right_interval, nodes, right, right_count);
            continue;
        }
        nodes[id].kind = 1;
        int[6][5] gaps = zeroed; int[6] gap_counts = zeroed; int gap = 0;
        for (int i = 0; i < child_count; i++) {
            int item = children[i]; if (nodes[item].sigma) gap++; else gaps[gap][gap_counts[gap]++] = item;
        }
        nodes[id].gap_count = sig_count + 1;
        for (int g = 0; g <= sig_count; g++) {
            if (gap_counts[g] == 0) { nodes[id].gap_left[g] = -1; nodes[id].gap_right[g] = -1; }
            else { nodes[id].gap_left[g] = nodes[gaps[g][0]].sa_left; nodes[id].gap_right[g] = nodes[gaps[g][gap_counts[g] - 1]].sa_right; }
        }
        for (int symbol = 0; symbol < sigma; symbol++) {
            int found = -1, preceding = 0;
            for (int i = 0; i < sig_count; i++) {
                int first = text[nodes[sigma_children[i]].edge_start];
                if (first == symbol) { found = sigma_children[i]; break; }
                if (first < symbol) preceding++;
            }
            if (found >= 0) nodes[id].child_by_symbol[symbol] = found;
            else if (gap_counts[preceding] > 0) nodes[id].group_by_symbol[symbol] = preceding;
        }
    }
}

fn int compare_suffix_pattern(int* text, int text_length, int suffix_start,
                              int* pattern, int q, int start_at, int* lcp) {
    int i = start_at;
    while (i < q && suffix_start + i < text_length) {
        if (text[suffix_start + i] != pattern[i]) { *lcp = i; return text[suffix_start + i] < pattern[i] ? -1 : 1; }
        i++;
    }
    *lcp = i; return i == q ? 1 : -1;
}

fn int interval_search(int* text, int text_length, int* pattern, int q, int* suffixes,
                       int lo, int hi, int known_prefix) {
    int low = lo - 1, high = hi + 1, low_lcp = known_prefix, high_lcp = known_prefix;
    while (high - low > 1) {
        int middle = (low + high) / 2, lcp = known_prefix;
        int start_at = low_lcp < high_lcp ? low_lcp : high_lcp;
        int comparison = compare_suffix_pattern(text, text_length, suffixes[middle], pattern, q, start_at, &lcp);
        if (comparison < 0) { low = middle; low_lcp = lcp; } else { high = middle; high_lcp = lcp; }
    }
    if (high > hi) return -1;
    int start = suffixes[high]; if (start + q > text_length) return -1;
    for (int i = 0; i < q; i++) if (text[start + i] != pattern[i]) return -1;
    return start;
}

fn int tray_query(int* text, int text_length, int* pattern, int q, int sigma,
                  int* suffixes, TrayNode* nodes) {
    int current = 0, matched = 0;
    while (true) {
        if (matched == q) return suffixes[nodes[current].sa_left];
        int symbol = pattern[matched];
        if (!nodes[current].sigma || nodes[current].kind == 3)
            return interval_search(text, text_length, pattern, q, suffixes, nodes[current].sa_left, nodes[current].sa_right, matched);
        int next = -1, interval_left = -1, interval_right = -1;
        if (nodes[current].kind == 1) {
            if (symbol < 0 || symbol >= sigma) return -1;
            next = nodes[current].child_by_symbol[symbol];
            if (next < 0) {
                int group = nodes[current].group_by_symbol[symbol];
                if (group < 0 || nodes[current].gap_left[group] < 0) return -1;
                interval_left = nodes[current].gap_left[group]; interval_right = nodes[current].gap_right[group];
            }
        } else {
            next = nodes[current].only_sigma_child;
            if (symbol != nodes[current].separator) {
                if (symbol < nodes[current].separator) {
                    if (!nodes[current].left_valid) return -1;
                    interval_left = nodes[current].left_interval[0]; interval_right = nodes[current].left_interval[1];
                } else {
                    if (!nodes[current].right_valid) return -1;
                    interval_left = nodes[current].right_interval[0]; interval_right = nodes[current].right_interval[1];
                }
            }
        }
        if (interval_left >= 0) return interval_search(text, text_length, pattern, q, suffixes, interval_left, interval_right, matched);
        if (next < 0) return -1;
        int representative = suffixes[nodes[next].sa_left], edge_position = nodes[current].depth;
        while (matched < q && edge_position < nodes[next].depth) {
            if (text[representative + edge_position] != pattern[matched]) return -1;
            matched++; edge_position++;
        }
        if (matched == q) return suffixes[nodes[next].sa_left];
        if (edge_position != nodes[next].depth) return -1;
        current = next;
    }
}

fn void put_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) { output[position + i] = (char)(bits & 255); bits >>= 8; }
}

fn long suffix_tray_pattern_query(long* input, usz length, char* output, usz capacity)
    @export("suffix_tray_pattern_query") {
    if (input == null || length < 3 || length > 24) return -1;
    long sigma64 = input[0], n64 = input[1], q64 = input[2];
    if (sigma64 < 2 || sigma64 > MAX_SIGMA || n64 < 1 || n64 > MAX_TEXT || q64 < 1 || q64 > MAX_PATTERN) return -1;
    int sigma = (int)sigma64, n = (int)n64, q = (int)q64;
    if (length != (usz)(3 + n + q)) return -1;
    int[MAX_SUFFIXES] text; int[MAX_PATTERN] pattern;
    for (int i = 0; i < n; i++) { if (input[3+i] < 0 || input[3+i] >= sigma) return -1; text[i] = (int)input[3+i]; }
    text[n] = -1;
    for (int i = 0; i < q; i++) { if (input[3+n+i] < 0 || input[3+n+i] >= sigma) return -1; pattern[i] = (int)input[3+n+i]; }
    if (output == null || capacity < MAX_OUTPUT) return -2;
    int[MAX_SUFFIXES] suffixes = zeroed; int[MAX_SUFFIXES] rank = zeroed;
    build_suffix_array(text, n + 1, suffixes, rank);
    TrayNode[MAX_NODES] nodes = zeroed;
    for (int i = 0; i < MAX_NODES; i++) init_node(&nodes[i], 0, 0, 0, -1);
    int node_count = 1;
    for (int start = 0; start <= n; start++) insert_suffix(&nodes[0], &node_count, text, n + 1, start);
    summarize_node(&nodes[0], 0, rank);
    build_tray(&nodes[0], node_count, sigma, text);
    int found = tray_query(text, n + 1, pattern, q, sigma, suffixes, &nodes[0]);
    put_i64_le(output, 0, found < 0 ? 0 : 1); put_i64_le(output, 8, found);
    return (long)MAX_OUTPUT;
}
