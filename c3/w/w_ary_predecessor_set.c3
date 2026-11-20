module w_ary_predecessor_set;

const long UNIVERSE = 262144;

fn uint low_bit(ulong bits) {
    uint low = 0, high = 64;
    while (high - low > 1) {
        uint middle = (low + high) / 2;
        ulong mask = ((ulong)1 << middle) - 1;
        if ((bits & mask) != 0) high = middle; else low = middle;
    }
    return low;
}

fn uint high_bit(ulong bits) {
    uint low = 0, high = 64;
    while (high - low > 1) {
        uint middle = (low + high) / 2;
        if ((bits >> middle) != 0) low = middle; else high = middle;
    }
    return low;
}

fn long insert_key(ulong* leaf, ulong* group, ulong* top, uint key) {
    uint word = key >> 6, bit_index = key & 63;
    ulong bit = (ulong)1 << bit_index, old = leaf[word];
    if ((old & bit) != 0) return 0;
    if (old == 0) {
        uint g = word >> 6, slot = word & 63;
        if (group[g] == 0) *top |= (ulong)1 << g;
        group[g] |= (ulong)1 << slot;
    }
    leaf[word] = old | bit;
    return 1;
}

fn long erase_key(ulong* leaf, ulong* group, ulong* top, uint key) {
    uint word = key >> 6, bit_index = key & 63;
    ulong bit = (ulong)1 << bit_index, old = leaf[word];
    if ((old & bit) == 0) return 0;
    leaf[word] = old & ~bit;
    if (leaf[word] == 0) {
        uint g = word >> 6, slot = word & 63;
        group[g] &= ~((ulong)1 << slot);
        if (group[g] == 0) *top &= ~((ulong)1 << g);
    }
    return 1;
}

fn long successor(const ulong* leaf, const ulong* group, ulong top, uint key) {
    uint word = key >> 6, bit_index = key & 63;
    ulong candidates = leaf[word] & (~(ulong)0 << bit_index);
    if (candidates != 0) return (long)(word * 64 + low_bit(candidates) + 1);
    uint g = word >> 6, slot = word & 63;
    ulong later = slot == 63 ? 0 : group[g] >> (slot + 1);
    uint next_word;
    if (later != 0) next_word = g * 64 + slot + 1 + low_bit(later);
    else {
        later = g == 63 ? 0 : top >> (g + 1);
        if (later == 0) return 0;
        uint next_group = g + 1 + low_bit(later);
        next_word = next_group * 64 + low_bit(group[next_group]);
    }
    return (long)(next_word * 64 + low_bit(leaf[next_word]) + 1);
}

fn long predecessor(const ulong* leaf, const ulong* group, ulong top, uint key) {
    uint word = key >> 6, bit_index = key & 63;
    ulong candidates = leaf[word] & (((ulong)1 << bit_index) - 1);
    if (candidates != 0) return (long)(word * 64 + high_bit(candidates) + 1);
    uint g = word >> 6, slot = word & 63;
    ulong earlier = group[g] & (((ulong)1 << slot) - 1);
    uint previous_word;
    if (earlier != 0) previous_word = g * 64 + high_bit(earlier);
    else {
        earlier = top & (((ulong)1 << g) - 1);
        if (earlier == 0) return 0;
        uint previous_group = high_bit(earlier);
        previous_word = previous_group * 64 + high_bit(group[previous_group]);
    }
    return (long)(previous_word * 64 + high_bit(leaf[previous_word]) + 1);
}

fn long w_ary_predecessor_set(long* input, usz length) @export("w_ary_predecessor_set") {
    if (input == null || length < 1 || length > 66) return -1;
    if (input[0] < 0 || input[0] > 32) return -1;
    usz q = (usz)input[0];
    if (length != 1 + 2 * q) return -1;
    ulong[4096] leaf = zeroed;
    ulong[64] group = zeroed;
    ulong top = 0;
    long result = 0;
    usz cursor = 1;
    for (usz i = 0; i < q; i++) {
        long opcode = input[cursor], raw_key = input[cursor + 1];
        cursor += 2;
        if (opcode < 0 || opcode > 4 || raw_key < 0 || raw_key >= UNIVERSE) return -1;
        uint key = (uint)raw_key;
        long answer;
        if (opcode == 0) answer = insert_key(&leaf[0], &group[0], &top, key);
        else if (opcode == 1) answer = erase_key(&leaf[0], &group[0], &top, key);
        else if (opcode == 2) answer = (leaf[key >> 6] & ((ulong)1 << (key & 63))) != 0;
        else if (opcode == 3) answer = successor(&leaf[0], &group[0], top, key);
        else answer = predecessor(&leaf[0], &group[0], top, key);
        result += (long)(i + 1) * answer;
    }
    return result;
}
