const std = @import("std");

const MAX_INITIAL_NODES: usize = 12;
const MAX_OPERATIONS: usize = 16;
const MAX_KNOWN_IDS: usize = MAX_INITIAL_NODES + 2 * MAX_OPERATIONS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 64;
const MAX_OUTPUT_WORDS: usize = 81;
const MAX_OUTPUT_BYTES: usize = 648;

fn findId(ids: *const [MAX_KNOWN_IDS]i64, count: usize, id: i64) ?usize {
    for (0..count) |index| {
        if (ids.*[index] == id) return index;
    }
    return null;
}

fn ensureId(ids: *[MAX_KNOWN_IDS]i64, declared: *[MAX_KNOWN_IDS]bool,
    count: *usize, id: i64) ?usize {
    if (findId(ids, count.*, id)) |found| return found;
    if (count.* >= MAX_KNOWN_IDS) return null;
    const index = count.*;
    count.* += 1;
    ids.*[index] = id;
    declared.*[index] = false;
    return index;
}

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn unweighted_graph(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if ((values[0] != 0 and values[0] != 1) or values[1] < 0 or values[1] > MAX_INITIAL_NODES or
        values[2] < 0 or values[2] > MAX_OPERATIONS) return -1;
    const directed = values[0] == 1;
    const initial_count: usize = @intCast(values[1]);
    const operation_count: usize = @intCast(values[2]);
    if (input_length != 3 + initial_count + operation_count * 3) return -1;

    var ids = [_]i64{0} ** MAX_KNOWN_IDS;
    var declared = [_]bool{false} ** MAX_KNOWN_IDS;
    var adjacency = [_]bool{false} ** (MAX_KNOWN_IDS * MAX_KNOWN_IDS);
    var known_count: usize = 0;
    for (0..initial_count) |index| {
        const node = values[3 + index];
        if (node < std.math.minInt(i32) or node > std.math.maxInt(i32) or findId(&ids, known_count, node) != null) return -1;
        const slot = ensureId(&ids, &declared, &known_count, node) orelse return -1;
        declared[slot] = true;
    }

    var result = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var result_count: usize = 0;
    const operations_offset = 3 + initial_count;
    for (0..operation_count) |index| {
        const offset = operations_offset + index * 3;
        const op = values[offset];
        const first = values[offset + 1];
        const second = values[offset + 2];
        if (first < std.math.minInt(i32) or first > std.math.maxInt(i32) or
            second < std.math.minInt(i32) or second > std.math.maxInt(i32)) return -1;
        switch (op) {
            0 => {
                if (second != 0) return -1;
                if (findId(&ids, known_count, first)) |existing| {
                    if (declared[existing]) return -1;
                }
                const slot = ensureId(&ids, &declared, &known_count, first) orelse return -1;
                declared[slot] = true;
            },
            1 => {
                const from = findId(&ids, known_count, first) orelse return -1;
                if (!declared[from]) return -1;
                var to = findId(&ids, known_count, second);
                if (!directed) {
                    if (to) |slot| {
                        if (!declared[slot]) return -1;
                    } else return -1;
                }
                if (to == null) to = ensureId(&ids, &declared, &known_count, second);
                const destination = to orelse return -1;
                const edge_index = from * MAX_KNOWN_IDS + destination;
                if (adjacency[edge_index]) return -1;
                adjacency[edge_index] = true;
                if (!directed) adjacency[destination * MAX_KNOWN_IDS + from] = true;
            },
            2 => {
                if (second != 0) return -1;
                const node = findId(&ids, known_count, first) orelse return -1;
                if (!declared[node]) return -1;
                var sorted = [_]i64{0} ** MAX_KNOWN_IDS;
                var neighbor_count: usize = 0;
                for (0..known_count) |neighbor| {
                    if (adjacency[node * MAX_KNOWN_IDS + neighbor]) {
                        sorted[neighbor_count] = ids[neighbor];
                        neighbor_count += 1;
                    }
                }
                std.mem.sort(i64, sorted[0..neighbor_count], {}, comptime std.sort.asc(i64));
                if (result_count + 2 + neighbor_count > MAX_OUTPUT_WORDS) return -1;
                result[result_count] = first;
                result[result_count + 1] = @intCast(neighbor_count);
                result_count += 2;
                for (0..neighbor_count) |neighbor| {
                    result[result_count] = sorted[neighbor];
                    result_count += 1;
                }
            },
            else => return -1,
        }
    }

    const output_bytes = result_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    const output_ptr = output orelse return -2;
    if (capacity < output_bytes) return -2;
    const output_slice = output_ptr[0..output_bytes];
    for (0..result_count) |index| writeI64Le(output_slice, index * 8, result[index]);
    return @intCast(output_bytes);
}
