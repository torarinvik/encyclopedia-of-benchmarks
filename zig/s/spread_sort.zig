const MAX_LENGTH: usize = 128;
const INSERTION_THRESHOLD: usize = 16;
const MAX_BUCKETS: usize = 8;
const BUCKET_STRIDE: usize = 128;

fn spreadSortSegment(values: []i32) void {
    if (values.len < 2) return;
    if (values.len <= INSERTION_THRESHOLD) {
        for (1..values.len) |index| {
            const key = values[index];
            var position = index;
            while (position > 0 and values[position - 1] > key) {
                values[position] = values[position - 1];
                position -= 1;
            }
            values[position] = key;
        }
        return;
    }

    var minimum = values[0];
    var maximum = values[0];
    for (values[1..]) |value| {
        minimum = @min(minimum, value);
        maximum = @max(maximum, value);
    }
    if (minimum == maximum) return;

    const bucket_count = @max(values.len / INSERTION_THRESHOLD, 2);
    const middle_bucket = bucket_count / 2;
    var bucket_values: [MAX_BUCKETS * BUCKET_STRIDE]i32 = undefined;
    var bucket_sizes = [_]usize{0} ** MAX_BUCKETS;
    for (values) |value| {
        const bucket: usize = if (value == minimum) 0 else middle_bucket;
        const position = bucket * BUCKET_STRIDE + bucket_sizes[bucket];
        bucket_values[position] = value;
        bucket_sizes[bucket] += 1;
    }

    var written: usize = 0;
    for (0..bucket_count) |bucket| {
        const count = bucket_sizes[bucket];
        if (count == 0) continue;
        const base = bucket * BUCKET_STRIDE;
        spreadSortSegment(bucket_values[base .. base + count]);
        @memcpy(values[written .. written + count], bucket_values[base .. base + count]);
        written += count;
    }
}

export fn spread_sort(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (@intFromPtr(input) == 0 or length > MAX_LENGTH) return -1;

    var values: [MAX_LENGTH]i32 = undefined;
    for (0..length) |index| {
        const value = input[index];
        if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return -1;
        values[index] = @intCast(value);
    }
    if (length == 0) return 0;

    const output_bytes = length * 4;
    if (@intFromPtr(output) == 0 or capacity < output_bytes) return -2;
    spreadSortSegment(values[0..length]);
    for (0..length) |index| {
        const bits: u32 = @bitCast(values[index]);
        output[index * 4] = @truncate(bits);
        output[index * 4 + 1] = @truncate(bits >> 8);
        output[index * 4 + 2] = @truncate(bits >> 16);
        output[index * 4 + 3] = @truncate(bits >> 24);
    }
    return @intCast(output_bytes);
}

const std = @import("std");
