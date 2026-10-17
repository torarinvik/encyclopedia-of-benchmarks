const MAX_CAPACITY: usize = 64;
const MAX_OPERATIONS: usize = 256;
const MAP_SIZE: usize = 1024;
const PUT_SENTINEL: i64 = -9223372036854775808;

const CacheNode = struct { key: i32 = 0, value: i32 = 0, previous: i32 = -1, next: i32 = -1 };
const MapEntry = struct { key: i32 = 0, node: i32 = -1, state: u8 = 0 };

fn hashKey(key: i32) usize {
    const bits: u32 = @bitCast(key);
    return @as(usize, bits *% 2_654_435_761) & (MAP_SIZE - 1);
}

fn mapFind(map: *const [MAP_SIZE]MapEntry, key: i32) i32 {
    const start = hashKey(key);
    for (0..MAP_SIZE) |probe| {
        const index = (start + probe) & (MAP_SIZE - 1);
        if (map[index].state == 0) return -1;
        if (map[index].state == 1 and map[index].key == key) return map[index].node;
    }
    return -1;
}

fn mapInsert(map: *[MAP_SIZE]MapEntry, key: i32, node: i32) bool {
    var slot = hashKey(key);
    var tombstone = MAP_SIZE;
    for (0..MAP_SIZE) |_| {
        if (map[slot].state == 1 and map[slot].key == key) return false;
        if (map[slot].state == 2 and tombstone == MAP_SIZE) tombstone = slot;
        if (map[slot].state == 0) {
            if (tombstone != MAP_SIZE) slot = tombstone;
            map[slot] = .{ .key = key, .node = node, .state = 1 };
            return true;
        }
        slot = (slot + 1) & (MAP_SIZE - 1);
    }
    if (tombstone != MAP_SIZE) {
        map[tombstone] = .{ .key = key, .node = node, .state = 1 };
        return true;
    }
    return false;
}

fn mapRemove(map: *[MAP_SIZE]MapEntry, key: i32) void {
    var slot = hashKey(key);
    for (0..MAP_SIZE) |_| {
        if (map[slot].state == 0) return;
        if (map[slot].state == 1 and map[slot].key == key) { map[slot].state = 2; return; }
        slot = (slot + 1) & (MAP_SIZE - 1);
    }
}

fn unlink(nodes: *[MAX_CAPACITY]CacheNode, head: *i32, tail: *i32, node: usize) void {
    const previous = nodes[node].previous;
    const next = nodes[node].next;
    if (previous < 0) head.* = next else nodes[@intCast(previous)].next = next;
    if (next < 0) tail.* = previous else nodes[@intCast(next)].previous = previous;
}

fn linkHead(nodes: *[MAX_CAPACITY]CacheNode, head: *i32, tail: *i32, node: usize) void {
    nodes[node].previous = -1;
    nodes[node].next = head.*;
    if (head.* < 0) tail.* = @intCast(node) else nodes[@intCast(head.*)].previous = @intCast(node);
    head.* = @intCast(node);
}

fn promote(nodes: *[MAX_CAPACITY]CacheNode, head: *i32, tail: *i32, node: usize) void {
    if (head.* == @as(i32, @intCast(node))) return;
    unlink(nodes, head, tail, node);
    linkHead(nodes, head, tail, node);
}

fn storeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn lru_cache2(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 771) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > 64 or input[1] < 0 or input[1] > 256) return -1;
    const cache_capacity: usize = @intCast(input[0]);
    const operation_count: usize = @intCast(input[1]);
    if (length != 2 + 3 * operation_count) return -1;

    var nodes: [MAX_CAPACITY]CacheNode = @splat(.{});
    var map: [MAP_SIZE]MapEntry = @splat(.{});
    var seen_put_keys: [MAX_OPERATIONS]i32 = @splat(0);
    var seen_count: usize = 0;
    var head: i32 = -1;
    var tail: i32 = -1;
    var node_count: usize = 0;
    var results: [MAX_OPERATIONS]i64 = @splat(0);

    for (0..operation_count) |operation| {
        const base = 2 + operation * 3;
        const opcode = input[base];
        const first = input[base + 1];
        const second = input[base + 2];
        if (opcode < 0 or opcode > 4) return -1;
        if (opcode == 0) {
            if (first < -2147483648 or first > 2147483647 or second < -2147483648 or second > 2147483647) return -1;
            const key: i32 = @intCast(first);
            for (0..seen_count) |index| if (seen_put_keys[index] == key) return -1;
            seen_put_keys[seen_count] = key;
            seen_count += 1;
            var node: usize = 0;
            if (node_count < cache_capacity) {
                node = node_count;
                node_count += 1;
            } else {
                node = @intCast(tail);
                mapRemove(&map, nodes[node].key);
                unlink(&nodes, &head, &tail, node);
            }
            nodes[node].key = key;
            nodes[node].value = @intCast(second);
            if (!mapInsert(&map, key, @intCast(node))) return -1;
            linkHead(&nodes, &head, &tail, node);
            results[operation] = PUT_SENTINEL;
        } else if (opcode == 1) {
            if (first < -2147483648 or first > 2147483647 or second != 0) return -1;
            const node_value = mapFind(&map, @intCast(first));
            if (node_value < 0) return -1;
            const node: usize = @intCast(node_value);
            promote(&nodes, &head, &tail, node);
            results[operation] = nodes[node].value;
        } else {
            if (first != 0 or second != 0) return -1;
            results[operation] = if (opcode == 2) @intCast(node_count) else if (opcode == 3) @intCast(cache_capacity) else if (node_count == 0) 1 else 0;
        }
    }

    const output_bytes = operation_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..operation_count) |operation| storeI64(output, operation * 8, results[operation]);
    return @intCast(output_bytes);
}
