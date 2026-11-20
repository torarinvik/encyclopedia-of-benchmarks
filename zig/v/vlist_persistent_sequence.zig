const MAX_Q: usize = 48;
const MAX_CONS: usize = 32;
const MAX_ROOTS: usize = 49;
const MAX_BLOCKS: usize = 6;
const MAX_SLOTS: usize = 63;
const MAX_PARSEABLE: usize = 146;

const Block = struct {
    previous_block: i32,
    previous_offset: i32,
    capacity: i32,
    last_used: i32,
    base: i32,
};

fn listLength(blocks: []const Block, root_block: []const i32,
              root_offset: []const i32, root: usize) i64 {
    var block_id = root_block[root];
    var offset = root_offset[root];
    var total: i64 = 0;
    while (block_id >= 0) {
        const b: usize = @intCast(block_id);
        if (b >= blocks.len or offset < 0 or offset > blocks[b].last_used) return -1;
        total += @as(i64, offset) + 1;
        offset = blocks[b].previous_offset;
        block_id = blocks[b].previous_block;
    }
    return total;
}

fn listNth(blocks: []const Block, data: []const i64, root_block: []const i32,
           root_offset: []const i32, root: usize, index: i64) ?i64 {
    var block_id = root_block[root];
    var offset = root_offset[root];
    var remaining = index;
    while (block_id >= 0) {
        const b: usize = @intCast(block_id);
        if (b >= blocks.len or offset < 0 or offset > blocks[b].last_used) return null;
        if (remaining <= offset) {
            const position: usize = @intCast(blocks[b].base + offset - @as(i32, @intCast(remaining)));
            if (position >= data.len) return null;
            return data[position];
        }
        remaining -= @as(i64, offset) + 1;
        offset = blocks[b].previous_offset;
        block_id = blocks[b].previous_block;
    }
    return null;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn vlist_persistent_sequence(input: ?[*]const i64, length: usize,
                                        output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE) return -1;
    const values = input.?;
    const q_word = values[0];
    if (q_word < 1 or q_word > @as(i64, @intCast(MAX_Q))) return -1;
    const q: usize = @intCast(q_word);
    if (length != 1 + 3 * q) return -1;

    var blocks: [MAX_BLOCKS]Block = undefined;
    var data: [MAX_SLOTS]i64 = undefined;
    var root_block: [MAX_ROOTS]i32 = @splat(-1);
    var root_offset: [MAX_ROOTS]i32 = @splat(-1);
    var results: [MAX_Q]i64 = undefined;
    var block_count: usize = 0;
    var root_count: usize = 1;
    var slot_count: usize = 0;
    var cons_count: usize = 0;
    var query_phase = false;
    var at: usize = 1;
    for (0..q) |op| {
        const tag = values[at];
        const root_word = values[at + 1];
        const arg = values[at + 2];
        at += 3;
        if (tag < 0 or tag > 3 or root_word < 0 or root_word >= @as(i64, @intCast(root_count))) return -1;
        const root: usize = @intCast(root_word);
        if (tag == 0) {
            if (query_phase or root != root_count - 1 or cons_count >= MAX_CONS or
                arg < -1_000_000 or arg > 1_000_000) return -1;
            var block_id = root_block[root];
            var offset = root_offset[root];
            if (block_id < 0) {
                if (cons_count != 0 or block_count != 0 or slot_count >= MAX_SLOTS) return -1;
                blocks[block_count] = .{ .previous_block = -1, .previous_offset = -1,
                    .capacity = 1, .last_used = 0, .base = @intCast(slot_count) };
                data[slot_count] = arg;
                block_id = @intCast(block_count);
                offset = 0;
                block_count += 1;
                slot_count += 1;
            } else {
                const b: usize = @intCast(block_id);
                if (b >= block_count or offset != blocks[b].last_used) return -1;
                if (offset + 1 < blocks[b].capacity) {
                    offset += 1;
                    data[@intCast(blocks[b].base + offset)] = arg;
                    blocks[b].last_used = offset;
                } else {
                    const next_capacity: usize = @intCast(blocks[b].capacity * 2);
                    if (block_count >= MAX_BLOCKS or slot_count + next_capacity > MAX_SLOTS) return -1;
                    blocks[block_count] = .{ .previous_block = block_id, .previous_offset = offset,
                        .capacity = @intCast(next_capacity), .last_used = 0,
                        .base = @intCast(slot_count) };
                    data[slot_count] = arg;
                    block_id = @intCast(block_count);
                    offset = 0;
                    block_count += 1;
                    slot_count += next_capacity;
                }
            }
            if (root_count >= MAX_ROOTS) return -1;
            root_block[root_count] = block_id;
            root_offset[root_count] = offset;
            results[op] = @intCast(root_count);
            root_count += 1;
            cons_count += 1;
        } else {
            query_phase = true;
            if (tag == 1) {
                if (arg != -1 or listLength(blocks[0..block_count], root_block[0..root_count],
                    root_offset[0..root_count], root) <= 0) return -1;
                var block_id = root_block[root];
                var offset = root_offset[root];
                if (offset > 0) {
                    offset -= 1;
                } else {
                    const b: usize = @intCast(block_id);
                    offset = blocks[b].previous_offset;
                    block_id = blocks[b].previous_block;
                }
                if (root_count >= MAX_ROOTS) return -1;
                root_block[root_count] = block_id;
                root_offset[root_count] = offset;
                results[op] = @intCast(root_count);
                root_count += 1;
            } else if (tag == 2) {
                const n = listLength(blocks[0..block_count], root_block[0..root_count],
                    root_offset[0..root_count], root);
                if (n < 0 or arg < 0 or arg >= n) return -1;
                const value = listNth(blocks[0..block_count], data[0..slot_count],
                    root_block[0..root_count], root_offset[0..root_count], root, arg) orelse return -1;
                results[op] = value;
            } else {
                if (arg != -1) return -1;
                const n = listLength(blocks[0..block_count], root_block[0..root_count],
                    root_offset[0..root_count], root);
                if (n < 0) return -1;
                results[op] = n;
            }
        }
    }
    const bytes = q * 8;
    const out = output orelse return -2;
    if (capacity < bytes) return -2;
    for (0..q) |i| storeI64Le(out, i * 8, results[i]);
    return @intCast(bytes);
}
