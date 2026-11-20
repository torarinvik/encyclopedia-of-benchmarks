const MAX_CAPACITY: i64 = 8;
const MAX_REQUESTS: usize = 64;
const PAGE_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 67;
const CHECKSUM_RADIX: i64 = 33_281;

export fn belady_optimal_paging(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const capacity_value = values[0];
    const count_value = values[1];
    if (capacity_value < 1 or capacity_value > MAX_CAPACITY or count_value < 0
        or count_value > MAX_REQUESTS or length != 2 + @as(usize, @intCast(count_value))) return -1;
    const capacity: usize = @intCast(capacity_value);
    const count: usize = @intCast(count_value);
    var requests: [MAX_REQUESTS]usize = @splat(0);
    for (0..count) |time| {
        if (values[2 + time] < 0 or values[2 + time] >= PAGE_COUNT) return -1;
        requests[time] = @intCast(values[2 + time]);
    }
    var next_after: [MAX_REQUESTS][PAGE_COUNT]usize = @splat(@splat(count));
    var next_position: [PAGE_COUNT]usize = @splat(count);
    var cursor = count;
    while (cursor > 0) {
        cursor -= 1;
        next_after[cursor] = next_position;
        next_position[requests[cursor]] = cursor;
    }

    var resident: [PAGE_COUNT]bool = @splat(false);
    var resident_count: usize = 0;
    var misses: i64 = 0;
    var eviction_checksum: i64 = 0;
    for (0..count) |time| {
        const requested = requests[time];
        if (resident[requested]) continue;
        misses += 1;
        if (resident_count == capacity) {
            var victim: usize = PAGE_COUNT;
            var farthest: usize = 0;
            for (0..PAGE_COUNT) |page| {
                if (resident[page] and (victim == PAGE_COUNT or next_after[time][page] > farthest)) {
                    victim = page;
                    farthest = next_after[time][page];
                }
            }
            resident[victim] = false;
            resident_count -= 1;
            eviction_checksum += @intCast((time + 1) * (victim + 1));
        }
        resident[requested] = true;
        resident_count += 1;
    }
    return misses * CHECKSUM_RADIX + eviction_checksum;
}
