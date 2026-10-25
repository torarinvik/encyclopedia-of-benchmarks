// Clean-room bounded MUMmerGPU maximal exact-match query; full source notice is package-local.
module rodinia_mummergpu;

const int MM_MAX_REF = 32, MM_MAX_QUERY = 32, MM_ALPHABET = 5;
const int MM_MAX_NODES = 1 + MM_MAX_REF * (MM_MAX_REF + 3) / 2;
const int MM_MAX_INPUT = 3 + MM_MAX_REF + MM_MAX_QUERY;
const int MM_MAX_MATCHES = MM_MAX_REF * MM_MAX_QUERY;

fn int mm_child_index(int node, int symbol) { return node * MM_ALPHABET + symbol; }
fn bool mm_suffix_less(long* reference, int length, int left, int right) {
    int a = left, b = right;
    while (a < length && b < length && reference[a] == reference[b]) { a++; b++; }
    if (a == length && b == length) return false;
    if (a == length) return false;
    if (b == length) return true;
    return reference[a] < reference[b];
}
fn void mm_put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(u8)(bits >> (8 * byte));
}

fn long rodinia_mummergpu(long* input, usz length, char* output, usz capacity) @export("rodinia_mummergpu") {
    if (input == null || length < 5 || length > MM_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MM_MAX_REF || input[1] < 1 || input[1] > MM_MAX_QUERY || input[2] < 1 || input[2] > MM_MAX_QUERY) return -1;
    int ref_len = (int)input[0], query_len = (int)input[1], min_len = (int)input[2];
    if (length != (usz)(3 + ref_len + query_len)) return -1;
    long[MM_MAX_REF] reference; long[MM_MAX_QUERY] query;
    for (int i = 0; i < ref_len; i++) { long code = input[3 + i]; if (code < 0 || code > 3) return -1; reference[i] = code; }
    for (int i = 0; i < query_len; i++) { long code = input[3 + ref_len + i]; if (code < 0 || code > 3) return -1; query[i] = code; }

    int[MM_MAX_NODES * MM_ALPHABET] children;
    int[MM_MAX_REF * (MM_MAX_REF + 1)] path_node;
    int[MM_MAX_REF] suffix_order;
    for (int i = 0; i < MM_MAX_NODES * MM_ALPHABET; i++) children[i] = -1;
    for (int i = 0; i < MM_MAX_REF * (MM_MAX_REF + 1); i++) path_node[i] = -1;
    int node_count = 1;
    for (int start = 0; start < ref_len; start++) {
        int node = 0, depth = 0;
        path_node[start * (MM_MAX_REF + 1)] = 0;
        for (int pos = start; pos < ref_len; pos++) {
            int slot = mm_child_index(node, (int)reference[pos]);
            if (children[slot] < 0) {
                int fresh = node_count++; children[slot] = fresh;
                for (int symbol = 0; symbol < MM_ALPHABET; symbol++) children[mm_child_index(fresh, symbol)] = -1;
            }
            node = children[slot]; depth++;
            path_node[start * (MM_MAX_REF + 1) + depth] = node;
        }
        int terminal_slot = mm_child_index(node, 4);
        if (children[terminal_slot] < 0) {
            int fresh = node_count++; children[terminal_slot] = fresh;
            for (int symbol = 0; symbol < MM_ALPHABET; symbol++) children[mm_child_index(fresh, symbol)] = -1;
        }
    }
    for (int i = 0; i < ref_len; i++) suffix_order[i] = i;
    for (int i = 1; i < ref_len; i++) {
        int key = suffix_order[i], j = i;
        while (j > 0 && mm_suffix_less(&reference[0], ref_len, key, suffix_order[j - 1])) { suffix_order[j] = suffix_order[j - 1]; j--; }
        suffix_order[j] = key;
    }

    long[MM_MAX_MATCHES * 3] records; usz match_count = 0;
    for (int qstart = 0; qstart < query_len; qstart++) {
        int[MM_MAX_REF] candidate;
        for (int r = 0; r < ref_len; r++) candidate[r] = -1;
        int node = 0, depth = 0;
        while (true) {
            bool query_has_next = qstart + depth < query_len;
            for (int rstart = 0; rstart < ref_len; rstart++) {
                if (path_node[rstart * (MM_MAX_REF + 1) + depth] != node) continue;
                bool suffix_ends = rstart + depth == ref_len;
                if (suffix_ends || !query_has_next || reference[rstart + depth] != query[qstart + depth]) candidate[rstart] = depth;
            }
            if (!query_has_next) break;
            int slot = mm_child_index(node, (int)query[qstart + depth]);
            if (children[slot] < 0) break;
            node = children[slot]; depth++;
        }
        for (int order = 0; order < ref_len; order++) {
            int rstart = suffix_order[order], match_len = candidate[rstart];
            if (match_len < min_len) continue;
            if (qstart > 0 && rstart > 0 && query[qstart - 1] == reference[rstart - 1]) continue;
            records[3 * match_count] = (long)rstart + 1;
            records[3 * match_count + 1] = (long)qstart + 1;
            records[3 * match_count + 2] = match_len;
            match_count++;
        }
    }
    usz output_bytes = match_count * 24;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < 3 * match_count; i++) mm_put_i64(output, i * 8, records[i]);
    return (long)output_bytes;
}
