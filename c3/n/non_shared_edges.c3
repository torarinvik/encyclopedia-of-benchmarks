module non_shared_edges;

const usz MAX_LEAVES = 8;
const usz MAX_EDGES = 13;
const usz MAX_INPUT = 27;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn usz bit_count(ulong value, usz n) {
    usz count = 0;
    for (usz bit = 0; bit < n; bit += 1) count += (usz)((value >> bit) & 1);
    return count;
}

fn bool valid_tree(long* input, usz offset, usz n, usz edges) {
    ulong[MAX_EDGES] masks = zeroed;
    ulong[MAX_EDGES] internal = zeroed;
    usz internal_count = 0;
    ulong universe = (1UL << n) - 1;
    for (usz edge = 0; edge < edges; edge += 1) {
        long raw = input[offset + edge];
        if (raw <= 0 || (ulong)raw >= universe || (raw & 1) != 0) return false;
        masks[edge] = (ulong)raw;
        for (usz earlier = 0; earlier < edge; earlier += 1) if (masks[earlier] == masks[edge]) return false;
        usz size = bit_count(masks[edge], n);
        if (size == 1 || size == n - 1) {
            if (size == n - 1 && masks[edge] != (universe ^ 1)) return false;
        } else if (size >= 2 && size <= n - 2) {
            internal[internal_count] = masks[edge];
            internal_count += 1;
        } else return false;
    }
    if (internal_count != n - 3) return false;
    for (usz leaf = 1; leaf < n; leaf += 1) {
        ulong pendant = 1UL << leaf;
        usz found = 0;
        for (usz edge = 0; edge < edges; edge += 1) if (masks[edge] == pendant) found += 1;
        if (found != 1) return false;
    }
    usz root_pendant = 0;
    for (usz edge = 0; edge < edges; edge += 1) if (masks[edge] == (universe ^ 1)) root_pendant += 1;
    if (root_pendant != 1) return false;
    for (usz i = 0; i < internal_count; i += 1) {
        for (usz j = i + 1; j < internal_count; j += 1) {
            ulong intersection = internal[i] & internal[j];
            if (intersection != 0 && intersection != internal[i] && intersection != internal[j]) return false;
        }
    }
    return true;
}

long non_shared_edges(long* input, usz length, char* output, usz capacity) @export("non_shared_edges") {
    if (input == null || length < 7 || length > MAX_INPUT) return -1;
    long leaf_value = input[0];
    if (leaf_value < 3 || leaf_value > (long)MAX_LEAVES) return -1;
    usz leaves = (usz)leaf_value;
    usz edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges) return -1;
    usz second = 1 + edges;
    if (!valid_tree(input, 1, leaves, edges) || !valid_tree(input, second, leaves, edges)) return -1;
    long shared = 0;
    for (usz left = 0; left < edges; left += 1) {
        for (usz right = 0; right < edges; right += 1) {
            if (input[1 + left] == input[second + right]) { shared += 1; break; }
        }
    }
    if (output == null || capacity < 8) return -2;
    char[8] staged = zeroed;
    store_i64_le(&staged[0], (long)edges - shared);
    for (usz byte = 0; byte < 8; byte += 1) output[byte] = staged[byte];
    return 8;
}
