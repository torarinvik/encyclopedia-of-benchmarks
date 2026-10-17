const MAX_ITEMS: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_ITEMS + 2;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

const PairingNode = struct {
    key: i32,
    first_child: i32,
    next_sibling: i32,
};

fn meld(first_root: i32, second_root: i32, nodes: *[MAX_ITEMS]PairingNode) i32 {
    if (first_root < 0) return second_root;
    if (second_root < 0) return first_root;
    var first = first_root;
    var second = second_root;
    if (nodes[@intCast(second)].key < nodes[@intCast(first)].key) {
        const temporary = first;
        first = second;
        second = temporary;
    }
    nodes[@intCast(second)].next_sibling = nodes[@intCast(first)].first_child;
    nodes[@intCast(first)].first_child = second;
    nodes[@intCast(first)].next_sibling = -1;
    return first;
}

fn hashKey(hash_value: u64, key: i32) u64 {
    var hash = hash_value;
    const bits: u32 = @bitCast(key);
    inline for (0..4) |byte| {
        const octet: u64 = @intCast((bits >> @as(u5, @intCast(byte * 8))) & 0xff);
        hash = (hash ^ octet) *% FNV_PRIME;
    }
    return hash;
}

export fn pairing_heap(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const raw_count = values[0];
    if (raw_count < 2 or raw_count > @as(i64, @intCast(MAX_ITEMS))) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 1 + count) return -1;

    var nodes: [MAX_ITEMS]PairingNode = undefined;
    for (0..count) |index| {
        const value = values[1 + index];
        if (value < -2147483648 or value > 2147483647) return -1;
        for (0..index) |previous| {
            if (values[1 + previous] == value) return -1;
        }
        nodes[index] = .{
            .key = @intCast(value),
            .first_child = -1,
            .next_sibling = -1,
        };
    }

    var root: i32 = -1;
    for (0..count) |index| {
        root = meld(root, @intCast(index), &nodes);
    }

    var hash = FNV_OFFSET_BASIS;
    for (0..count - 1) |_| {
        const removed: usize = @intCast(root);
        hash = hashKey(hash, nodes[removed].key);
        var forest: [MAX_ITEMS]i32 = @splat(-1);
        var paired: [MAX_ITEMS]i32 = @splat(-1);
        var forest_count: usize = 0;
        var child = nodes[removed].first_child;
        nodes[removed].first_child = -1;
        while (child >= 0) {
            const child_index: usize = @intCast(child);
            const next = nodes[child_index].next_sibling;
            nodes[child_index].next_sibling = -1;
            forest[forest_count] = child;
            forest_count += 1;
            child = next;
        }

        var paired_count: usize = 0;
        var index: usize = 0;
        while (index < forest_count) : (index += 2) {
            const right: i32 = if (index + 1 < forest_count) forest[index + 1] else -1;
            paired[paired_count] = meld(forest[index], right, &nodes);
            paired_count += 1;
        }
        var rebuilt: i32 = -1;
        while (paired_count > 0) {
            paired_count -= 1;
            rebuilt = meld(rebuilt, paired[paired_count], &nodes);
        }
        root = rebuilt;
    }
    return @intCast(hash & MASK_63);
}
