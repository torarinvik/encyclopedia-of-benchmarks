const std = @import("std");

const MAX_ARRAY_SIZE: i64 = 100_000;
const MAX_ROUNDS: i64 = 8;
const MAX_SCANS_PER_ARRAY: i64 = 64;

fn puzzle_rand(state: *u64) u32 {
    state.* = state.* *% 1_103_515_245 +% 12_345;
    const shifted: u32 = @truncate(state.* >> 16);
    return shifted % 32_767 + 1;
}

fn puzzle_rand_int(minimum: usize, maximum: usize, state: *u64) usize {
    const range = maximum - minimum + 1;
    const draw = puzzle_rand(state);
    const offset: usize = @intFromFloat(@as(f64, @floatFromInt(range)) *
        (@as(f64, @floatFromInt(draw)) / 32_768.0));
    return if (offset == range) offset + minimum - 1 else offset + minimum;
}

fn puzzle_shuffle(items: []i32, state: *u64) void {
    var index = items.len - 1;
    while (index > 0) : (index -= 1) {
        const range = index + 1;
        const draw = puzzle_rand(state);
        const k: usize = @intFromFloat(@as(f64, @floatFromInt(range)) *
            (@as(f64, @floatFromInt(draw)) / 32_768.0));
        const chosen = if (k == range) k - 1 else k;
        const temporary = items[index];
        items[index] = items[chosen];
        items[chosen] = temporary;
    }
}

fn puzzle_find_duplicate(data: []const i32) i32 {
    var result: u32 = 0;
    for (data, 0..) |item, index| result ^= @as(u32, @intCast(index + 1)) ^ @as(u32, @bitCast(item));
    result ^= @intCast(data.len);
    return @bitCast(result);
}

fn puzzle_store_i32_le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn benchmarkgame_puzzle(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    const raw_size = input[0];
    const raw_rounds = input[1];
    const raw_scans = input[2];
    if (raw_size < 1 or raw_size > MAX_ARRAY_SIZE or raw_rounds < 1 or raw_rounds > MAX_ROUNDS or
        raw_scans < 1 or raw_scans > MAX_SCANS_PER_ARRAY) return -1;
    const size: usize = @intCast(raw_size);
    const rounds: usize = @intCast(raw_rounds);
    const scans: usize = @intCast(raw_scans);
    const output_bytes = rounds * 4;
    if (output_capacity < output_bytes or output == null) return -2;

    const allocator = std.heap.page_allocator;
    var random_state: u64 = 1;
    for (0..rounds) |round| {
        const data = allocator.alloc(i32, size + 1) catch return -1;
        for (0..size + 1) |index| data[index] = @intCast(index);
        data[0] = @intCast(puzzle_rand_int(1, size, &random_state));
        puzzle_shuffle(data, &random_state);
        var duplicate: i32 = 0;
        for (0..scans) |_| duplicate = puzzle_find_duplicate(data);
        puzzle_store_i32_le(output, round * 4, duplicate);
        allocator.free(data);
    }
    return @intCast(output_bytes);
}
