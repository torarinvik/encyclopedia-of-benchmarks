// Bounded clean-room TAR-header filename search benchmark.
// Embench-IoT source declares MIT; see the package attribution.
// SPDX-License-Identifier: MIT
const MAX_RECORDS: usize = 35;
const MAX_QUERIES: usize = 5;
const MIN_NAME_LENGTH: usize = 5;
const MAX_NAME_LENGTH: usize = 39;
const MAX_INPUT_LENGTH: usize =
    2 + MAX_RECORDS * (1 + MAX_NAME_LENGTH) + MAX_QUERIES * (1 + MAX_NAME_LENGTH);

pub export fn tarfind(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 or input[0] > @as(i64, MAX_RECORDS) or
        input[1] < 1 or input[1] > @as(i64, MAX_QUERIES)) return -1;
    const record_count: usize = @intCast(input[0]);
    const query_count: usize = @intCast(input[1]);
    var record_offsets = [_]usize{0} ** MAX_RECORDS;
    var record_lengths = [_]usize{0} ** MAX_RECORDS;
    var query_offsets = [_]usize{0} ** MAX_QUERIES;
    var query_lengths = [_]usize{0} ** MAX_QUERIES;
    var staged = [_]u8{0} ** MAX_QUERIES;
    var position: usize = 2;

    for (0..record_count) |i| {
        if (position >= input_length) return -1;
        const raw_length = input[position];
        position += 1;
        if (raw_length < @as(i64, MIN_NAME_LENGTH) or raw_length > @as(i64, MAX_NAME_LENGTH)) return -1;
        const name_length: usize = @intCast(raw_length);
        if (name_length > input_length - position) return -1;
        record_offsets[i] = position;
        record_lengths[i] = name_length;
        for (0..name_length) |j| {
            if (input[position + j] < 65 or input[position + j] > 90) return -1;
        }
        position += name_length;
    }
    for (0..query_count) |i| {
        if (position >= input_length) return -1;
        const raw_length = input[position];
        position += 1;
        if (raw_length < @as(i64, MIN_NAME_LENGTH) or raw_length > @as(i64, MAX_NAME_LENGTH)) return -1;
        const name_length: usize = @intCast(raw_length);
        if (name_length > input_length - position) return -1;
        query_offsets[i] = position;
        query_lengths[i] = name_length;
        for (0..name_length) |j| {
            if (input[position + j] < 65 or input[position + j] > 90) return -1;
        }
        position += name_length;
    }
    if (position != input_length) return -1;
    if (output == null or output_capacity < query_count) return -2;

    for (0..query_count) |q| {
        var found: i64 = -1;
        for (0..record_count) |i| {
            if (record_lengths[i] != query_lengths[q]) continue;
            var j: usize = 0;
            while (j < query_lengths[q] and
                input[record_offsets[i] + j] == input[query_offsets[q] + j]) : (j += 1) {}
            if (j == query_lengths[q]) {
                found = @intCast(i);
                break;
            }
        }
        staged[q] = if (found < 0) 255 else @intCast(found);
    }
    for (0..query_count) |q| output[q] = staged[q];
    return @intCast(query_count);
}
