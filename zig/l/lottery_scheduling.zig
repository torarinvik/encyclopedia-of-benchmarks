const MAX_PROCESSES: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 51;
const MAX_OUTPUT_BYTES: usize = 384;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = (1 << 48) - 1;
const INT32_MAX_VALUE: u64 = 0x7fffffff;

fn nextJavaState(state: u64) u64 {
    const low = state & 0xffffff;
    const high = state >> 24;
    const low_product = low * JAVA_MULTIPLIER;
    const high_product = (high * JAVA_MULTIPLIER) & 0xffffff;
    return (low_product + (high_product << 24) + JAVA_ADDEND) & JAVA_MASK;
}

fn javaNextInt(state: *u64, bound: u64) u64 {
    if ((bound & (bound - 1)) == 0) {
        state.* = nextJavaState(state.*);
        return (bound * (state.* >> 17)) >> 31;
    }
    while (true) {
        state.* = nextJavaState(state.*);
        const bits = state.* >> 17;
        const value = bits % bound;
        if (bits - value + (bound - 1) <= INT32_MAX_VALUE) return value;
    }
}

export fn lottery_scheduling(input: [*c]const i64, input_length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[1] < 0 or input[1] > 16) return -1;
    const process_count: usize = @intCast(input[1]);
    if (input_length != 2 + 3 * process_count) return -1;

    var process_ids = [_]i64{0} ** MAX_PROCESSES;
    var burst_times = [_]i64{0} ** MAX_PROCESSES;
    var ticket_counts = [_]i64{0} ** MAX_PROCESSES;
    var total_tickets: i64 = 0;
    var total_burst_time: i64 = 0;
    for (0..process_count) |index| {
        const process_id = input[2 + 3 * index];
        const burst_time = input[3 + 3 * index];
        const tickets = input[4 + 3 * index];
        if (process_id < 0 or process_id > 32767 or burst_time < 1 or burst_time > 1000 or
            tickets < 1 or tickets > 1000) return -1;
        for (0..index) |prior| {
            if (process_ids[prior] == process_id) return -1;
        }
        process_ids[index] = process_id;
        burst_times[index] = burst_time;
        ticket_counts[index] = tickets;
        total_tickets += tickets;
        total_burst_time += burst_time;
    }
    if (total_tickets > 16000 or total_burst_time > 16000) return -1;

    const seed_bits: u64 = @bitCast(input[0]);
    var random_state = (seed_bits ^ JAVA_MULTIPLIER) & JAVA_MASK;
    var words = [_]i64{0} ** (3 * MAX_PROCESSES);
    var word_count: usize = 0;
    var current_time: i64 = 0;
    var remaining = process_count;
    while (remaining > 0) {
        var current_total_tickets: i64 = 0;
        for (0..remaining) |index| current_total_tickets += ticket_counts[index];
        const winning_ticket = javaNextInt(&random_state, @intCast(current_total_tickets)) + 1;
        var cumulative_tickets: u64 = 0;
        var selected = remaining;
        for (0..remaining) |index| {
            cumulative_tickets += @intCast(ticket_counts[index]);
            if (cumulative_tickets >= winning_ticket) { selected = index; break; }
        }
        if (selected == remaining) return -1;

        const waiting_time = current_time;
        const turnaround_time = waiting_time + burst_times[selected];
        words[word_count] = process_ids[selected];
        words[word_count + 1] = waiting_time;
        words[word_count + 2] = turnaround_time;
        word_count += 3;
        current_time += burst_times[selected];
        for (selected + 1..remaining) |index| {
            process_ids[index - 1] = process_ids[index];
            burst_times[index - 1] = burst_times[index];
            ticket_counts[index - 1] = ticket_counts[index];
        }
        remaining -= 1;
    }

    const output_bytes = word_count * 8;
    if (output == null or capacity < output_bytes or output_bytes > MAX_OUTPUT_BYTES) return -2;
    for (0..word_count) |index| {
        const bits: u64 = @bitCast(words[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
