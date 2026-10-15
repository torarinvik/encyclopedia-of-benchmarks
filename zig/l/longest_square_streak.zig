const MAX_INPUT_LENGTH: usize = 100_000;
const MAX_VALUE: usize = 100_000;
const REQUIRED_WORKSPACE: usize = 4 * (MAX_VALUE + 1);

fn readState(workspace: [*]const u8, value: usize) i64 {
    const position = 4 * value;
    const encoded = @as(u32, workspace[position]) |
        (@as(u32, workspace[position + 1]) << 8) |
        (@as(u32, workspace[position + 2]) << 16) |
        (@as(u32, workspace[position + 3]) << 24);
    return @intCast(encoded);
}

fn writeState(workspace: [*]u8, value: usize, state: i64) void {
    const encoded: u32 = @bitCast(@as(i32, @intCast(state)));
    const position = 4 * value;
    workspace[position] = @truncate(encoded);
    workspace[position + 1] = @truncate(encoded >> 8);
    workspace[position + 2] = @truncate(encoded >> 16);
    workspace[position + 3] = @truncate(encoded >> 24);
}

fn streakFrom(workspace: [*]u8, value: usize) i64 {
    const state = readState(workspace, value);
    if (state > 1) return state - 1;
    var chain_length: i64 = 1;
    const square = @as(u64, @intCast(value)) * @as(u64, @intCast(value));
    if (square <= @as(u64, MAX_VALUE) and readState(workspace, @intCast(square)) != 0) {
        chain_length += streakFrom(workspace, @intCast(square));
    }
    writeState(workspace, value, chain_length + 1);
    return chain_length;
}

export fn longest_square_streak(values: [*]const i64, length: usize,
    workspace: [*]u8, workspace_capacity: usize) i64 {
    if (length < 3 or length > MAX_INPUT_LENGTH + 1 or
        values[0] < 2 or values[0] > MAX_INPUT_LENGTH or
        length != @as(usize, @intCast(values[0])) + 1) return -1;
    const count: usize = @intCast(values[0]);
    for (0..count) |index| {
        const value = values[index + 1];
        if (value < 2 or value > MAX_VALUE) return -1;
    }
    if (workspace_capacity < REQUIRED_WORKSPACE) return -2;
    @memset(workspace[0..REQUIRED_WORKSPACE], 0);
    for (0..count) |index| writeState(workspace, @intCast(values[index + 1]), 1);
    var longest: i64 = 1;
    for (0..count) |index| {
        longest = @max(longest, streakFrom(workspace, @intCast(values[index + 1])));
    }
    return if (longest >= 2) longest else -1;
}
