const MAX_REQUESTS: usize = 7;
const MAX_FILES: usize = 8;
const MAX_INPUT: usize = 23;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn landlord_file_caching(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const capacity_value = input[0];
    const count_value = input[1];
    if (capacity_value < 1 or capacity_value > 8 or count_value < 0 or count_value > @as(i64, MAX_REQUESTS) or
        length != 2 + 3 * @as(usize, @intCast(count_value))) return -1;
    var known_size: [MAX_FILES]i64 = @splat(0);
    var known_cost: [MAX_FILES]i64 = @splat(0);
    var seen: [MAX_FILES]bool = @splat(false);
    const count: usize = @intCast(count_value);
    for (0..count) |request| {
        const id_value = input[2 + 3 * request];
        const size = input[3 + 3 * request];
        const cost = input[4 + 3 * request];
        if (id_value < 0 or id_value >= @as(i64, MAX_FILES) or size < 1 or size > 4 or size > capacity_value or cost < 0 or cost > 20) return -1;
        const id: usize = @intCast(id_value);
        if (seen[id] and (known_size[id] != size or known_cost[id] != cost)) return -1;
        seen[id] = true;
        known_size[id] = size;
        known_cost[id] = cost;
    }
    var ids: [MAX_FILES]i64 = @splat(0);
    var sizes: [MAX_FILES]i64 = @splat(0);
    var credits: [MAX_FILES]i64 = @splat(0);
    var resident_count: usize = 0;
    var misses: i64 = 0;
    var total_cost: i64 = 0;
    var hit_signature: u64 = 0;
    var eviction_signature: u64 = 0;
    var resident_mask: u64 = 0;
    for (0..count) |request| {
        const id = input[2 + 3 * request];
        const size = input[3 + 3 * request];
        const cost = input[4 + 3 * request];
        var position: usize = 0;
        while (position < resident_count and ids[position] != id) : (position += 1) {}
        if (position < resident_count) {
            hit_signature |= @as(u64, 1) << @intCast(request);
            continue;
        }
        misses += 1;
        total_cost += cost;
        var evicted_mask: u64 = 0;
        var used: i64 = 0;
        for (0..resident_count) |i| used += sizes[i];
        while (used + size > capacity_value) {
            var delta = credits[0] / sizes[0];
            for (1..resident_count) |i| {
                const ratio = credits[i] / sizes[i];
                if (ratio < delta) delta = ratio;
            }
            var kept: usize = 0;
            used = 0;
            for (0..resident_count) |i| {
                credits[i] -= delta * sizes[i];
                if (credits[i] == 0) evicted_mask |= @as(u64, 1) << @intCast(ids[i]) else {
                    ids[kept] = ids[i];
                    sizes[kept] = sizes[i];
                    credits[kept] = credits[i];
                    used += sizes[kept];
                    kept += 1;
                }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << @intCast(8 * request);
        ids[resident_count] = id;
        sizes[resident_count] = size;
        credits[resident_count] = cost * 12;
        resident_count += 1;
    }
    for (0..resident_count) |i| resident_mask |= @as(u64, 1) << @intCast(ids[i]);
    if (output_opt == null or capacity < 40) return -2;
    const output = output_opt.?;
    var staged: [40]u8 = @splat(0);
    store_i64_le(&staged, 0, misses);
    store_i64_le(&staged, 8, total_cost);
    store_i64_le(&staged, 16, @intCast(hit_signature));
    store_i64_le(&staged, 24, @intCast(eviction_signature));
    store_i64_le(&staged, 32, @intCast(resident_mask));
    for (0..40) |byte| output[byte] = staged[byte];
    return 40;
}
