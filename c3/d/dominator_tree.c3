module dominator_tree;

const usz MAX_VERTEX_COUNT = 63;
const usz MAX_EDGE_COUNT = 2047;
const usz MAX_INPUT_LENGTH = 3 + 2 * MAX_EDGE_COUNT;

fn usz count_bits(ulong value) {
    usz count = 0;
    while (value != 0ul) {
        value &= value - 1ul;
        count++;
    }
    return count;
}

fn long dominator_tree(long* input, usz length, char* output, usz output_capacity)
    @export("dominator_tree") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH || input[0] < 1 ||
        input[0] > (long)MAX_VERTEX_COUNT || input[1] < 0 || input[1] >= input[0] ||
        input[2] < 0 || input[2] > (long)MAX_EDGE_COUNT) return -1;
    usz vertex_count = (usz)input[0];
    usz root = (usz)input[1];
    usz edge_count = (usz)input[2];
    if (length != 3 + 2 * edge_count) return -1;

    ulong[MAX_VERTEX_COUNT] outgoing;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) outgoing[vertex] = 0ul;
    for (usz edge = 0; edge < edge_count; edge++) {
        long from_value = input[3 + 2 * edge];
        long to_value = input[4 + 2 * edge];
        if (from_value < 0 || to_value < 0 || (ulong)from_value >= (ulong)vertex_count ||
            (ulong)to_value >= (ulong)vertex_count) return -1;
        outgoing[(usz)from_value] |= 1ul << (ulong)to_value;
    }

    ulong reachable = 1ul << (ulong)root;
    ulong frontier = reachable;
    while (frontier != 0ul) {
        ulong discovered = 0ul;
        for (usz vertex = 0; vertex < vertex_count; vertex++)
            if ((frontier & (1ul << (ulong)vertex)) != 0ul) discovered |= outgoing[vertex];
        discovered &= ~reachable;
        reachable |= discovered;
        frontier = discovered;
    }

    ulong[MAX_VERTEX_COUNT] dominators;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) dominators[vertex] = 0ul;
    dominators[root] = 1ul << (ulong)root;
    for (usz vertex = 0; vertex < vertex_count; vertex++)
        if ((reachable & (1ul << (ulong)vertex)) != 0ul && vertex != root)
            dominators[vertex] = reachable;

    bool changed = true;
    while (changed) {
        changed = false;
        for (usz vertex = 0; vertex < vertex_count; vertex++) {
            ulong vertex_bit = 1ul << (ulong)vertex;
            if ((reachable & vertex_bit) == 0ul || vertex == root) continue;
            ulong common = reachable;
            for (usz predecessor = 0; predecessor < vertex_count; predecessor++)
                if ((reachable & (1ul << (ulong)predecessor)) != 0ul &&
                    (outgoing[predecessor] & vertex_bit) != 0ul)
                    common &= dominators[predecessor];
            ulong updated = common | vertex_bit;
            if (updated != dominators[vertex]) {
                dominators[vertex] = updated;
                changed = true;
            }
        }
    }

    if (output == null || output_capacity < vertex_count) return -2;
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        ulong vertex_bit = 1ul << (ulong)vertex;
        if ((reachable & vertex_bit) == 0ul) {
            output[vertex] = (char)255;
        } else if (vertex == root) {
            output[vertex] = (char)root;
        } else {
            ulong strict = dominators[vertex] & ~vertex_bit;
            usz best = root;
            usz best_depth = 0;
            for (usz candidate = 0; candidate < vertex_count; candidate++) {
                if ((strict & (1ul << (ulong)candidate)) == 0ul) continue;
                usz depth = count_bits(dominators[candidate]);
                if (depth > best_depth) {
                    best = candidate;
                    best_depth = depth;
                }
            }
            output[vertex] = (char)best;
        }
    }
    return (long)vertex_count;
}
