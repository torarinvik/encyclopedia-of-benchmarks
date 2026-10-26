const MAX_PACKETS: usize = 16;
const MAX_SLOTS: usize = 8;
const MAX_INPUT: usize = 38;
const MAX_OUTPUT_BYTES: usize = 64;
const BETA: i64 = 15;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn erase_packet(ids: *[MAX_PACKETS]i64, values: *[MAX_PACKETS]i64,
    count: *usize, index: usize) void {
    var position = index;
    while (position + 1 < count.*) : (position += 1) {
        ids.*[position] = ids.*[position + 1];
        values.*[position] = values.*[position + 1];
    }
    count.* -= 1;
}

export fn packet_switching_single_buffer(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const mode = input[0];
    const buffer = input[1];
    const beta = input[2];
    const slots_value = input[3];
    const count_value = input[4];
    if (mode < 0 or mode > 2 or buffer < 1 or buffer > 4 or slots_value < 1 or slots_value > @as(i64, MAX_SLOTS) or
        count_value < 0 or count_value > @as(i64, MAX_PACKETS) or (mode == 0 and beta != 0) or (mode != 0 and beta != BETA)) return -1;
    const slots: usize = @intCast(slots_value);
    const packet_count: usize = @intCast(count_value);
    if (length != 5 + 2 * packet_count) return -1;
    var arrival: [MAX_PACKETS]i64 = @splat(0);
    var packet_value: [MAX_PACKETS]i64 = @splat(0);
    var previous_slot: i64 = -1;
    for (0..packet_count) |packet| {
        arrival[packet] = input[5 + 2 * packet];
        packet_value[packet] = input[6 + 2 * packet];
        if (arrival[packet] < 0 or arrival[packet] >= slots_value or arrival[packet] < previous_slot or
            packet_value[packet] < 1 or packet_value[packet] > 100) return -1;
        previous_slot = arrival[packet];
    }
    var resident_id: [MAX_PACKETS]i64 = @splat(0);
    var resident_value: [MAX_PACKETS]i64 = @splat(0);
    var schedule: [MAX_SLOTS]i64 = @splat(-1);
    var resident_count: usize = 0;
    var next_packet: usize = 0;
    for (0..slots) |slot| {
        while (next_packet < packet_count and arrival[next_packet] == @as(i64, @intCast(slot))) {
            const value = packet_value[next_packet];
            var preempt = resident_count;
            if (mode == 1) {
                for (0..resident_count) |index| {
                    if (resident_value[index] * BETA <= value) { preempt = index; break; }
                }
            } else if (mode == 2) {
                for (0..resident_count) |index| {
                    const following_ok = index + 1 == resident_count or resident_value[index] <= resident_value[index + 1];
                    if (resident_value[index] * BETA < value and following_ok) { preempt = index; break; }
                }
            }
            if (preempt < resident_count) {
                erase_packet(&resident_id, &resident_value, &resident_count, preempt);
                resident_id[resident_count] = @intCast(next_packet);
                resident_value[resident_count] = value;
                resident_count += 1;
            } else if (resident_count < @as(usize, @intCast(buffer))) {
                resident_id[resident_count] = @intCast(next_packet);
                resident_value[resident_count] = value;
                resident_count += 1;
            } else {
                var smallest = resident_value[0];
                for (1..resident_count) |index| {
                    if (resident_value[index] < smallest) smallest = resident_value[index];
                }
                if (value > smallest) {
                    var evict: usize = 0;
                    while (resident_value[evict] != smallest) : (evict += 1) {}
                    erase_packet(&resident_id, &resident_value, &resident_count, evict);
                    resident_id[resident_count] = @intCast(next_packet);
                    resident_value[resident_count] = value;
                    resident_count += 1;
                }
            }
            next_packet += 1;
        }
        if (resident_count > 0) {
            schedule[slot] = resident_id[0];
            erase_packet(&resident_id, &resident_value, &resident_count, 0);
        }
    }
    const output_bytes = 8 * slots;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..slots) |slot| store_i64_le(&staged, 8 * slot, schedule[slot]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
