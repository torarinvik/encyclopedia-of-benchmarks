const ARENA: usize = 256;
const MAX_ORDER: usize = 8;
const MAX_OPS: usize = 64;
const MAX_IDS: usize = 32;
const MAX_INPUT_WORDS: usize = 194;
const MAX_OUTPUT_WORDS: usize = 3 * MAX_OPS + 1 + 2 * ARENA;

export fn buddy_system_allocator(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length == 0 or length > MAX_INPUT_WORDS) return -1;
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > @as(i64, @intCast(MAX_OPS)) or length != 1 + 3 * @as(usize, @intCast(raw_count))) return -1;
    const count: usize = @intCast(raw_count);

    var free_blocks: [MAX_ORDER + 1][ARENA]bool = undefined;
    for (0..MAX_ORDER + 1) |order| @memset(&free_blocks[order], false);
    var active: [MAX_IDS]bool = @splat(false);
    var allocation_base: [MAX_IDS]usize = @splat(0);
    var allocation_order: [MAX_IDS]usize = @splat(0);
    var staged: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    free_blocks[MAX_ORDER][0] = true;
    var staged_words: usize = 0;

    for (0..count) |i| {
        const opcode = values[1 + 3 * i];
        const raw_id = values[2 + 3 * i];
        const argument = values[3 + 3 * i];
        if (raw_id < 0 or raw_id >= @as(i64, @intCast(MAX_IDS))) return -1;
        const id: usize = @intCast(raw_id);
        if (opcode == 0) {
            if (argument < 1 or argument > @as(i64, @intCast(ARENA)) or active[id]) return -1;
            var target: usize = 0;
            var rounded: usize = 1;
            while (rounded < @as(usize, @intCast(argument))) : (target += 1) rounded <<= 1;
            var found_order: usize = MAX_ORDER + 1;
            var found_base: usize = ARENA;
            var order = target;
            while (order <= MAX_ORDER) : (order += 1) {
                const size = @as(usize, 1) << @intCast(order);
                var base: usize = 0;
                while (base + size <= ARENA) : (base += size) {
                    if (free_blocks[order][base]) { found_order = order; found_base = base; break; }
                }
                if (found_order <= MAX_ORDER) break;
            }
            if (found_order > MAX_ORDER) {
                staged[staged_words] = 0; staged[staged_words + 1] = -1; staged[staged_words + 2] = 0;
                staged_words += 3;
                continue;
            }
            free_blocks[found_order][found_base] = false;
            while (found_order > target) {
                found_order -= 1;
                const half = @as(usize, 1) << @intCast(found_order);
                free_blocks[found_order][found_base + half] = true;
            }
            active[id] = true;
            allocation_base[id] = found_base;
            allocation_order[id] = target;
            staged[staged_words] = 1;
            staged[staged_words + 1] = @intCast(found_base);
            staged[staged_words + 2] = @intCast(@as(usize, 1) << @intCast(target));
            staged_words += 3;
        } else if (opcode == 1) {
            if (argument != 0 or !active[id]) return -1;
            const original_base = allocation_base[id];
            const original_order = allocation_order[id];
            const original_size = @as(usize, 1) << @intCast(original_order);
            active[id] = false;
            var base = original_base;
            var order = original_order;
            while (order < MAX_ORDER) : (order += 1) {
                const buddy = base ^ (@as(usize, 1) << @intCast(order));
                if (!free_blocks[order][buddy]) break;
                free_blocks[order][buddy] = false;
                if (buddy < base) base = buddy;
            }
            free_blocks[order][base] = true;
            staged[staged_words] = 1;
            staged[staged_words + 1] = @intCast(original_base);
            staged[staged_words + 2] = @intCast(original_size);
            staged_words += 3;
        } else return -1;
    }

    const count_index = staged_words;
    staged[staged_words] = 0;
    staged_words += 1;
    for (0..ARENA) |base| {
        var order: usize = MAX_ORDER + 1;
        while (order > 0) {
            order -= 1;
            if (free_blocks[order][base]) {
                staged[count_index] += 1;
                staged[staged_words] = @intCast(base);
                staged[staged_words + 1] = @intCast(@as(usize, 1) << @intCast(order));
                staged_words += 2;
                break;
            }
        }
    }

    const required = staged_words * 8;
    if (output == null or capacity < required) return -2;
    for (0..staged_words) |i| {
        const word: u64 = @bitCast(staged[i]);
        for (0..8) |byte| output[8 * i + byte] = @truncate(word >> @intCast(8 * byte));
    }
    return @intCast(required);
}
