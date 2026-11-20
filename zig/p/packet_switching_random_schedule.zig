const MAX_QUEUES: usize = 4;
const MAX_BUFFER: usize = 4;
const MAX_SLOTS: usize = 8;
const MAX_PARSEABLE_INPUT: usize = 68;
const MAX_OUTPUT_BYTES: usize = 64;

const Tag = struct { priority: i64 = 0, marked: bool = false };

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn packet_switching_random_schedule(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > @as(i64, MAX_QUEUES) or input[1] < 1 or input[1] > @as(i64, MAX_BUFFER) or
        input[2] < 1 or input[2] > @as(i64, MAX_SLOTS)) return -1;
    const m: usize = @intCast(input[0]);
    const b: usize = @intCast(input[1]);
    const slots: usize = @intCast(input[2]);
    const cells = m * slots;
    if (length != 3 + 2 * cells) return -1;
    for (0..cells) |cell| {
        const flag = input[3 + cell];
        const priority = input[3 + cells + cell];
        if (flag < 0 or flag > 1 or priority < 0 or priority > 4_294_967_295) return -1;
    }
    var load: [MAX_QUEUES]usize = @splat(0);
    var count: [MAX_QUEUES]usize = @splat(0);
    var tags: [MAX_QUEUES][MAX_BUFFER]Tag = @splat(@splat(.{}));
    var trace: [MAX_SLOTS]i64 = @splat(-1);
    for (0..slots) |slot| {
        for (0..m) |q| {
            const cell = slot * m + q;
            if (input[3 + cell] == 0 or load[q] == b) continue;
            if (count[q] == b) {
                for (1..count[q]) |i| tags[q][i - 1] = tags[q][i];
                count[q] -= 1;
            }
            tags[q][count[q]] = .{ .priority = input[3 + cells + cell], .marked = false };
            count[q] += 1;
            load[q] += 1;
        }
        var best_q: usize = m;
        var best_i: usize = 0;
        var best_priority: i64 = -1;
        for (0..m) |q| for (0..count[q]) |i| {
            if (tags[q][i].marked) continue;
            if (best_q == m or tags[q][i].priority > best_priority) {
                best_q = q;
                best_i = i;
                best_priority = tags[q][i].priority;
            }
        };
        if (best_q < m) tags[best_q][best_i].marked = true else {
            for (0..m) |q| {
                if (load[q] > 0) { best_q = q; break; }
            }
        }
        if (best_q < m) { trace[slot] = @intCast(best_q); load[best_q] -= 1; }
    }
    const bytes = 8 * slots;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..slots) |slot| store_i64_le(&staged, 8 * slot, trace[slot]);
    for (0..bytes) |byte| output[byte] = staged[byte];
    return @intCast(bytes);
}
