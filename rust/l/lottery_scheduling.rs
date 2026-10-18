const MAX_PROCESSES: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 51;
const MAX_OUTPUT_BYTES: usize = 384;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = (1_u64 << 48) - 1;
const INT32_MAX_VALUE: u64 = 0x7FFF_FFFF;

fn next_java_state(state: u64) -> u64 {
    let low = state & 0xFF_FFFF;
    let high = state >> 24;
    let low_product = low * JAVA_MULTIPLIER;
    let high_product = (high * JAVA_MULTIPLIER) & 0xFF_FFFF;
    (low_product + (high_product << 24) + JAVA_ADDEND) & JAVA_MASK
}

fn java_next_int(state: &mut u64, bound: u64) -> u64 {
    if bound & (bound - 1) == 0 {
        *state = next_java_state(*state);
        return (bound * (*state >> 17)) >> 31;
    }
    loop {
        *state = next_java_state(*state);
        let bits = *state >> 17;
        let value = bits % bound;
        if bits - value + (bound - 1) <= INT32_MAX_VALUE { return value; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn lottery_scheduling(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_PROCESSES as i64).contains(&values[1]) { return -1; }
    let process_count = values[1] as usize;
    if input_length != 2 + 3 * process_count { return -1; }

    let mut process_ids = [0_i64; MAX_PROCESSES];
    let mut burst_times = [0_i64; MAX_PROCESSES];
    let mut ticket_counts = [0_i64; MAX_PROCESSES];
    let mut total_tickets = 0_i64;
    let mut total_burst_time = 0_i64;
    for index in 0..process_count {
        let process_id = values[2 + 3 * index];
        let burst_time = values[3 + 3 * index];
        let tickets = values[4 + 3 * index];
        if !(0..=32767).contains(&process_id) || !(1..=1000).contains(&burst_time) ||
            !(1..=1000).contains(&tickets) { return -1; }
        if (0..index).any(|prior| process_ids[prior] == process_id) { return -1; }
        process_ids[index] = process_id;
        burst_times[index] = burst_time;
        ticket_counts[index] = tickets;
        total_tickets += tickets;
        total_burst_time += burst_time;
    }
    if total_tickets > 16000 || total_burst_time > 16000 { return -1; }

    let mut random_state = ((values[0] as u64) ^ JAVA_MULTIPLIER) & JAVA_MASK;
    let mut words = [0_i64; 3 * MAX_PROCESSES];
    let mut word_count = 0_usize;
    let mut current_time = 0_i64;
    let mut remaining = process_count;
    while remaining > 0 {
        let current_total_tickets: i64 = ticket_counts[..remaining].iter().sum();
        let winning_ticket = java_next_int(&mut random_state, current_total_tickets as u64) + 1;
        let mut cumulative_tickets = 0_u64;
        let mut selected = remaining;
        for index in 0..remaining {
            cumulative_tickets += ticket_counts[index] as u64;
            if cumulative_tickets >= winning_ticket { selected = index; break; }
        }
        if selected == remaining { return -1; }

        let waiting_time = current_time;
        let turnaround_time = waiting_time + burst_times[selected];
        words[word_count] = process_ids[selected];
        words[word_count + 1] = waiting_time;
        words[word_count + 2] = turnaround_time;
        word_count += 3;
        current_time += burst_times[selected];
        for index in selected + 1..remaining {
            process_ids[index - 1] = process_ids[index];
            burst_times[index - 1] = burst_times[index];
            ticket_counts[index - 1] = ticket_counts[index];
        }
        remaining -= 1;
    }

    let output_bytes = word_count * 8;
    if output.is_null() || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES { return -2; }
    for index in 0..word_count {
        let bytes = words[index].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8);
    }
    output_bytes as i64
}
