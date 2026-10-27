const MAX_REQUESTS: usize = 7;
const MAX_FILES: usize = 8;
const MAX_INPUT: usize = 16;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn greedy_dual_weighted_caching(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const cache_capacity = input[0];
    const count_value = input[1];
    if (cache_capacity < 1 or cache_capacity > MAX_FILES or count_value < 0 or
        count_value > MAX_REQUESTS or length != 2 + 2 * @as(usize, @intCast(count_value))) return -1;
    const count: usize = @intCast(count_value);
    var known_cost: [MAX_FILES]i64 = @splat(0);
    var seen: [MAX_FILES]bool = @splat(false);
    for (0..count) |request| {
        const id = input[2 + 2 * request];
        const cost = input[3 + 2 * request];
        if (id < 0 or id >= MAX_FILES or cost < 0 or cost > 20) return -1;
        const slot: usize = @intCast(id);
        if (seen[slot] and known_cost[slot] != cost) return -1;
        seen[slot] = true;
        known_cost[slot] = cost;
    }
    var ids: [MAX_FILES]i64 = @splat(0);
    var credits: [MAX_FILES]i64 = @splat(0);
    var resident_count: usize = 0;
    var misses: i64 = 0;
    var total_cost: i64 = 0;
    var hit_signature: u64 = 0;
    var eviction_signature: u64 = 0;
    var resident_mask: u64 = 0;
    for (0..count) |request| {
        const id = input[2 + 2 * request];
        const cost = input[3 + 2 * request];
        var position: usize = 0;
        while (position < resident_count and ids[position] != id) : (position += 1) {}
        if (position < resident_count) {
            hit_signature |= @as(u64, 1) << @intCast(request);
            credits[position] = cost;
            continue;
        }
        misses += 1;
        total_cost += cost;
        var evicted_mask: u64 = 0;
        while (resident_count >= @as(usize, @intCast(cache_capacity))) {
            var delta = credits[0];
            for (1..resident_count) |i| if (credits[i] < delta) { delta = credits[i]; };
            var kept: usize = 0;
            for (0..resident_count) |i| {
                credits[i] -= delta;
                if (credits[i] == 0) evicted_mask |= @as(u64, 1) << @intCast(ids[i])
                else { ids[kept] = ids[i]; credits[kept] = credits[i]; kept += 1; }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << @intCast(8 * request);
        ids[resident_count] = id;
        credits[resident_count] = cost;
        resident_count += 1;
    }
    for (0..resident_count) |i| resident_mask |= @as(u64, 1) << @intCast(ids[i]);
    if (output_opt == null or output_capacity < 40) return -2;
    const output = output_opt.?;
    var staged: [40]u8 = @splat(0);
    store_i64_le(&staged, 0, misses);
    store_i64_le(&staged, 8, total_cost);
    store_i64_le(&staged, 16, @bitCast(hit_signature));
    store_i64_le(&staged, 24, @bitCast(eviction_signature));
    store_i64_le(&staged, 32, @bitCast(resident_mask));
    for (0..40) |byte| output[byte] = staged[byte];
    return 40;
}
