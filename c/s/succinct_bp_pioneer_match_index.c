#include <stddef.h>
#include <stdint.h>

enum { MAX_BITS = 64, BLOCK_BITS = 8, BASE_BITS = 16, LEVELS = 3,
       MAX_WORDS = 1 + MAX_BITS, MAX_INPUT = 66 };

typedef struct { uint16_t key; uint8_t start, count, cursor; } Group;
typedef struct {
    size_t length;
    uint8_t bits[MAX_BITS], mate[MAX_BITS], far[MAX_BITS], family[MAX_BITS];
    int16_t family_rank[MAX_BITS], depth[MAX_BITS + 1];
    uint8_t open_pioneer[MAX_BITS], close_pioneer[MAX_BITS];
    Group open_groups[MAX_BITS], close_groups[MAX_BITS];
    uint8_t open_members[MAX_BITS], close_members[MAX_BITS];
    size_t open_group_count, close_group_count;
} IndexLevel;

static IndexLevel levels[LEVELS];

static uint16_t group_key(size_t source, size_t target, int depth)
{
    return (uint16_t)((source << 10) | (target << 7) | (unsigned)depth);
}

static size_t find_group(const Group *groups, size_t count, uint16_t key)
{
    for (size_t i = 0; i < count; ++i) if (groups[i].key == key) return i;
    return MAX_BITS;
}

static void build_groups(IndexLevel *a, const int16_t *targets)
{
    for (size_t position = 0; position < a->length; ++position) {
        if (!a->far[position]) continue;
        size_t source = position / BLOCK_BITS, target = (size_t)targets[position];
        int depth = a->bits[position] ? a->depth[position] : a->depth[position + 1];
        Group *groups = a->bits[position] ? a->open_groups : a->close_groups;
        size_t *group_count = a->bits[position] ? &a->open_group_count : &a->close_group_count;
        size_t index = find_group(groups, *group_count, group_key(source, target, depth));
        if (index == MAX_BITS) {
            index = (*group_count)++;
            groups[index].key = group_key(source, target, depth);
            groups[index].count = 0;
        }
        groups[index].count += 1;
    }
    size_t open_offset = 0, close_offset = 0;
    for (size_t i = 0; i < a->open_group_count; ++i) {
        a->open_groups[i].start = (uint8_t)open_offset;
        a->open_groups[i].cursor = 0;
        open_offset += a->open_groups[i].count;
    }
    for (size_t i = 0; i < a->close_group_count; ++i) {
        a->close_groups[i].start = (uint8_t)close_offset;
        a->close_groups[i].cursor = 0;
        close_offset += a->close_groups[i].count;
    }
    for (size_t position = 0; position < a->length; ++position) {
        if (!a->far[position]) continue;
        size_t source = position / BLOCK_BITS, target = (size_t)targets[position];
        int depth = a->bits[position] ? a->depth[position] : a->depth[position + 1];
        Group *groups = a->bits[position] ? a->open_groups : a->close_groups;
        size_t count = a->bits[position] ? a->open_group_count : a->close_group_count;
        uint8_t *members = a->bits[position] ? a->open_members : a->close_members;
        size_t index = find_group(groups, count, group_key(source, target, depth));
        Group *group = &groups[index];
        members[group->start + group->cursor++] = (uint8_t)position;
    }
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t j = 0; j < 8; ++j) output[offset + j] = (uint8_t)(bits >> (8 * j));
}

static int build_level(size_t level, const uint8_t *bits, size_t length)
{
    if (level >= LEVELS || length > MAX_BITS) return 0;
    IndexLevel *a = &levels[level];
    a->length = length;
    size_t stack[MAX_BITS], top = 0;
    uint8_t matched[MAX_BITS] = {0};
    int16_t targets[MAX_BITS];
    for (size_t i = 0; i < length; ++i) {
        a->bits[i] = bits[i]; a->mate[i] = 0; a->far[i] = 0;
        a->family[i] = 0; a->family_rank[i] = -1; targets[i] = -1;
        a->open_pioneer[i] = 0; a->close_pioneer[i] = 0;
        if (bits[i]) stack[top++] = i;
        else {
            if (top == 0) return 0;
            size_t opening = stack[--top];
            matched[opening] = (uint8_t)i; matched[i] = (uint8_t)opening;
        }
    }
    if (top != 0) return 0;
    a->depth[0] = 0;
    for (size_t i = 0; i < length; ++i)
        a->depth[i + 1] = (int16_t)(a->depth[i] + (bits[i] ? 1 : -1));
    if (length <= BASE_BITS) {
        for (size_t i = 0; i < length; ++i) a->mate[i] = matched[i];
        return 1;
    }

    a->open_group_count = 0; a->close_group_count = 0;
    for (size_t i = 0; i < length; ++i) {
        size_t target = (size_t)matched[i] / BLOCK_BITS;
        if (target == i / BLOCK_BITS) a->mate[i] = matched[i];
        else { a->far[i] = 1; targets[i] = (int16_t)target; }
    }
    build_groups(a, targets);

    for (size_t start = 0; start < length; start += BLOCK_BITS) {
        size_t end = start + BLOCK_BITS < length ? start + BLOCK_BITS : length;
        int previous_target = -1;
        for (size_t i = start; i < end; ++i) {
            if (!bits[i] || !a->far[i]) continue;
            int target = targets[i];
            if (previous_target < 0 || target != previous_target) a->open_pioneer[i] = 1;
            previous_target = target;
        }
        int next_target = -1;
        for (size_t i = end; i-- > start;) {
            if (bits[i] || !a->far[i]) continue;
            int target = targets[i];
            if (next_target < 0 || target != next_target) a->close_pioneer[i] = 1;
            next_target = target;
        }
    }
    for (size_t i = 0; i < length; ++i) {
        if (a->open_pioneer[i] || a->close_pioneer[i]) {
            a->family[i] = 1; a->family[matched[i]] = 1;
        }
    }
    uint8_t child[MAX_BITS];
    size_t count = 0;
    for (size_t i = 0; i < length; ++i) if (a->family[i]) {
        a->family_rank[i] = (int16_t)count;
        child[count++] = a->bits[i];
    }
    return count > 0 && count < length && build_level(level + 1, child, count);
}

static int find_pioneer(const IndexLevel *a, size_t position, size_t *pioneer)
{
    size_t block_start = (position / BLOCK_BITS) * BLOCK_BITS;
    if (a->bits[position]) {
        for (size_t i = position + 1; i-- > block_start;)
            if (a->open_pioneer[i]) { *pioneer = i; return 1; }
    } else {
        size_t end = block_start + BLOCK_BITS;
        if (end > a->length) end = a->length;
        for (size_t i = position; i < end; ++i)
            if (a->close_pioneer[i]) { *pioneer = i; return 1; }
    }
    return 0;
}

static int match_position(size_t level, size_t position, size_t *answer)
{
    const IndexLevel *a = &levels[level];
    if (position >= a->length) return 0;
    if (a->length <= BASE_BITS || !a->far[position]) { *answer = a->mate[position]; return 1; }
    size_t pioneer;
    if (!find_pioneer(a, position, &pioneer)) return 0;
    size_t child_match;
    if (!match_position(level + 1, (size_t)a->family_rank[pioneer], &child_match)) return 0;
    size_t anchor = (size_t)a->family[child_match];
    size_t source = position / BLOCK_BITS, target = anchor / BLOCK_BITS;
    int target_depth;
    if (a->bits[position]) {
        int relative_excess = a->depth[position] - a->depth[pioneer];
        target_depth = a->depth[pioneer] + relative_excess;
        size_t src = find_group(a->open_groups, a->open_group_count, group_key(source, target, target_depth));
        size_t dst = find_group(a->close_groups, a->close_group_count, group_key(target, source, target_depth));
        if (src == MAX_BITS || dst == MAX_BITS) return 0;
        Group left = a->open_groups[src], right = a->close_groups[dst];
        size_t rank = 0;
        while (rank < left.count && a->open_members[left.start + rank] != position) ++rank;
        if (rank >= left.count || rank >= right.count) return 0;
        *answer = a->close_members[right.start + rank];
        return 1;
    }
    int relative_excess = a->depth[position + 1] - a->depth[pioneer + 1];
    target_depth = a->depth[pioneer + 1] + relative_excess;
    size_t src = find_group(a->close_groups, a->close_group_count, group_key(source, target, target_depth));
    size_t dst = find_group(a->open_groups, a->open_group_count, group_key(target, source, target_depth));
    if (src == MAX_BITS || dst == MAX_BITS) return 0;
    Group left = a->close_groups[src], right = a->open_groups[dst];
    size_t rank = 0;
    while (rank < left.count && a->close_members[left.start + rank] != position) ++rank;
    if (rank >= left.count || rank >= right.count) return 0;
    *answer = a->open_members[right.start + rank];
    return 1;
}

int64_t succinct_bp_pioneer_match_index(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0];
    if (n_value < 1 || n_value > 32 || length != 1 + 2 * (size_t)n_value) return -1;
    size_t bit_count = 2 * (size_t)n_value;
    uint8_t bits[MAX_BITS];
    int balance = 0;
    for (size_t i = 0; i < bit_count; ++i) {
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
        bits[i] = (uint8_t)input[i + 1];
        balance += bits[i] ? 1 : -1;
        if (balance < 0) return -1;
    }
    if (balance != 0 || !build_level(0, bits, bit_count)) return -1;
    size_t required = 8 * (1 + bit_count);
    if (output == NULL || capacity < required) return -2;
    int64_t words[MAX_WORDS];
    words[0] = (int64_t)bit_count;
    for (size_t i = 0; i < bit_count; ++i) {
        size_t mate;
        if (!match_position(0, i, &mate)) return -1;
        words[i + 1] = (int64_t)mate;
    }
    for (size_t i = 0; i < 1 + bit_count; ++i) write_i64_le(output, 8 * i, words[i]);
    return (int64_t)required;
}
