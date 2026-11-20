module succinct_bp_pioneer_match_index;

const usz MAX_BITS = 64;
const usz BLOCK_BITS = 8;
const usz BASE_BITS = 16;
const usz LEVELS = 3;
const usz MAX_INPUT = 66;

struct Group { ushort key; u8 start; u8 count; u8 cursor; }
struct Level {
    usz length;
    u8[MAX_BITS] bits;
    u8[MAX_BITS] mate;
    u8[MAX_BITS] far;
    u8[MAX_BITS] family;
    int[MAX_BITS] family_rank;
    int[MAX_BITS + 1] depth;
    u8[MAX_BITS] open_pioneer;
    u8[MAX_BITS] close_pioneer;
    Group[MAX_BITS] open_groups;
    Group[MAX_BITS] close_groups;
    u8[MAX_BITS] open_members;
    u8[MAX_BITS] close_members;
    usz open_group_count;
    usz close_group_count;
}

Level[LEVELS] levels;

fn ushort group_key(usz source, usz target, int depth) {
    return (ushort)((source << 10) | (target << 7) | (usz)depth);
}

fn usz find_group_exact(Group* groups, usz count, ushort key) {
    for (usz i = 0; i < count; i += 1) if (groups[i].key == key) return i;
    return MAX_BITS;
}

fn void build_groups(Level* a, int* targets) {
    for (usz position = 0; position < a.length; position += 1) {
        if (a.far[position] == 0) continue;
        usz source = position / BLOCK_BITS, target = (usz)targets[position];
        int depth = a.bits[position] != 0 ? a.depth[position] : a.depth[position + 1];
        Group* groups = a.bits[position] != 0 ? a.open_groups : a.close_groups;
        usz* group_count = a.bits[position] != 0 ? &a.open_group_count : &a.close_group_count;
        usz index = find_group_exact(groups, *group_count, group_key(source, target, depth));
        if (index == MAX_BITS) {
            index = *group_count;
            *group_count = *group_count + 1;
            groups[index].key = group_key(source, target, depth);
            groups[index].count = 0;
        }
        groups[index].count = groups[index].count + 1;
    }
    usz open_offset = 0, close_offset = 0;
    for (usz i = 0; i < a.open_group_count; i += 1) {
        a.open_groups[i].start = (u8)open_offset;
        a.open_groups[i].cursor = 0;
        open_offset += a.open_groups[i].count;
    }
    for (usz i = 0; i < a.close_group_count; i += 1) {
        a.close_groups[i].start = (u8)close_offset;
        a.close_groups[i].cursor = 0;
        close_offset += a.close_groups[i].count;
    }
    for (usz position = 0; position < a.length; position += 1) {
        if (a.far[position] == 0) continue;
        usz source = position / BLOCK_BITS, target = (usz)targets[position];
        int depth = a.bits[position] != 0 ? a.depth[position] : a.depth[position + 1];
        Group* groups = a.bits[position] != 0 ? a.open_groups : a.close_groups;
        usz count = a.bits[position] != 0 ? a.open_group_count : a.close_group_count;
        u8* members = a.bits[position] != 0 ? a.open_members : a.close_members;
        usz index = find_group_exact(groups, count, group_key(source, target, depth));
        Group* group = &groups[index];
        members[group.start + group.cursor] = (u8)position;
        group.cursor = group.cursor + 1;
    }
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) output[offset + b] = (char)((bits >> (8 * b)) & 255);
}

fn bool build_level(usz level, u8* bits, usz length) {
    if (level >= LEVELS || length > MAX_BITS) return false;
    Level* a = &levels[level];
    a.length = length;
    usz[MAX_BITS] stack = zeroed;
    u8[MAX_BITS] matched = zeroed;
    int[MAX_BITS] targets = zeroed;
    usz top = 0;
    for (usz i = 0; i < length; i += 1) {
        a.bits[i] = bits[i]; a.mate[i] = 0; a.far[i] = 0; a.family[i] = 0;
        a.family_rank[i] = -1; a.open_pioneer[i] = 0; a.close_pioneer[i] = 0;
        targets[i] = -1;
        if (bits[i] != 0) { stack[top] = i; top += 1; }
        else {
            if (top == 0) return false;
            top -= 1;
            usz opening = stack[top];
            matched[opening] = (u8)i; matched[i] = (u8)opening;
        }
    }
    if (top != 0) return false;
    a.depth[0] = 0;
    for (usz i = 0; i < length; i += 1)
        a.depth[i + 1] = a.depth[i] + (bits[i] != 0 ? 1 : -1);
    if (length <= BASE_BITS) {
        for (usz i = 0; i < length; i += 1) a.mate[i] = matched[i];
        return true;
    }
    a.open_group_count = 0; a.close_group_count = 0;
    for (usz i = 0; i < length; i += 1) {
        usz target = (usz)matched[i] / BLOCK_BITS;
        if (target == i / BLOCK_BITS) a.mate[i] = matched[i];
        else { a.far[i] = 1; targets[i] = (int)target; }
    }
    build_groups(a, targets);
    for (usz start = 0; start < length; start += BLOCK_BITS) {
        usz end = start + BLOCK_BITS;
        if (end > length) end = length;
        int previous_target = -1;
        for (usz i = start; i < end; i += 1) {
            if (bits[i] == 0 || a.far[i] == 0) continue;
            int target = targets[i];
            if (previous_target < 0 || target != previous_target) a.open_pioneer[i] = 1;
            previous_target = target;
        }
        int next_target = -1;
        usz i = end;
        while (i > start) {
            i -= 1;
            if (bits[i] != 0 || a.far[i] == 0) continue;
            int target = targets[i];
            if (next_target < 0 || target != next_target) a.close_pioneer[i] = 1;
            next_target = target;
        }
    }
    for (usz i = 0; i < length; i += 1) if (a.open_pioneer[i] != 0 || a.close_pioneer[i] != 0) {
        a.family[i] = 1; a.family[matched[i]] = 1;
    }
    u8[MAX_BITS] child = zeroed;
    usz count = 0;
    for (usz i = 0; i < length; i += 1) if (a.family[i] != 0) {
        a.family_rank[i] = (int)count;
        child[count] = a.bits[i]; count += 1;
    }
    return count > 0 && count < length && build_level(level + 1, child, count);
}

fn bool find_pioneer(Level* a, usz position, usz* result) {
    usz block_start = (position / BLOCK_BITS) * BLOCK_BITS;
    if (a.bits[position] != 0) {
        usz i = position + 1;
        while (i > block_start) {
            i -= 1;
            if (a.open_pioneer[i] != 0) { *result = i; return true; }
        }
    } else {
        usz end = block_start + BLOCK_BITS;
        if (end > a.length) end = a.length;
        for (usz i = position; i < end; i += 1)
            if (a.close_pioneer[i] != 0) { *result = i; return true; }
    }
    return false;
}

fn bool match_position(usz level, usz position, usz* result) {
    Level* a = &levels[level];
    if (position >= a.length) return false;
    if (a.length <= BASE_BITS || a.far[position] == 0) { *result = a.mate[position]; return true; }
    usz pioneer = 0;
    if (!find_pioneer(a, position, &pioneer)) return false;
    usz child_match = 0;
    if (!match_position(level + 1, (usz)a.family_rank[pioneer], &child_match)) return false;
    usz anchor = (usz)a.family[child_match];
    usz source = position / BLOCK_BITS, target = anchor / BLOCK_BITS;
    int target_depth;
    if (a.bits[position] != 0) {
        int relative_excess = a.depth[position] - a.depth[pioneer];
        target_depth = a.depth[pioneer] + relative_excess;
        usz src = find_group_exact(a.open_groups, a.open_group_count, group_key(source, target, target_depth));
        usz dst = find_group_exact(a.close_groups, a.close_group_count, group_key(target, source, target_depth));
        if (src == MAX_BITS || dst == MAX_BITS) return false;
        Group left = a.open_groups[src], right = a.close_groups[dst];
        usz rank = 0;
        while (rank < left.count && a.open_members[left.start + rank] != position) rank += 1;
        if (rank >= left.count || rank >= right.count) return false;
        *result = a.close_members[right.start + rank];
        return true;
    }
    int relative_excess = a.depth[position + 1] - a.depth[pioneer + 1];
    target_depth = a.depth[pioneer + 1] + relative_excess;
    usz src = find_group_exact(a.close_groups, a.close_group_count, group_key(source, target, target_depth));
    usz dst = find_group_exact(a.open_groups, a.open_group_count, group_key(target, source, target_depth));
    if (src == MAX_BITS || dst == MAX_BITS) return false;
    Group left = a.close_groups[src], right = a.open_groups[dst];
    usz rank = 0;
    while (rank < left.count && a.close_members[left.start + rank] != position) rank += 1;
    if (rank >= left.count || rank >= right.count) return false;
    *result = a.open_members[right.start + rank];
    return true;
}

fn long succinct_bp_pioneer_match_index(long* input, usz length, char* output, usz capacity)
    @export("succinct_bp_pioneer_match_index") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > 32 || length != 1 + 2 * (usz)n_value) return -1;
    usz bit_count = 2 * (usz)n_value;
    u8[MAX_BITS] bits = zeroed;
    int balance = 0;
    for (usz i = 0; i < bit_count; i += 1) {
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
        bits[i] = (u8)input[i + 1];
        balance += bits[i] != 0 ? 1 : -1;
        if (balance < 0) return -1;
    }
    if (balance != 0 || !build_level(0, bits, bit_count)) return -1;
    usz required = 8 * (1 + bit_count);
    if (output == null || capacity < required) return -2;
    long[MAX_WORDS] words = zeroed;
    words[0] = (long)bit_count;
    for (usz i = 0; i < bit_count; i += 1) {
        usz mate = 0;
        if (!match_position(0, i, &mate)) return -1;
        words[i + 1] = (long)mate;
    }
    for (usz i = 0; i < 1 + bit_count; i += 1) write_i64_le(output, 8 * i, words[i]);
    return (long)required;
}
