module lottery_scheduling;

const usz MAX_PROCESSES = 16;
const usz MAX_PARSEABLE_INPUT_LENGTH = 51;
const usz MAX_OUTPUT_BYTES = 384;
const ulong JAVA_MULTIPLIER = 0x5DEECE66D;
const ulong JAVA_ADDEND = 0xB;
const ulong JAVA_MASK = (1ul << 48) - 1;
const ulong INT32_MAX_VALUE = 0x7FFFFFFF;

fn ulong next_java_state(ulong state) {
    ulong low = state & 0xFFFFFF;
    ulong high = state >> 24;
    ulong low_product = low * JAVA_MULTIPLIER;
    ulong high_product = (high * JAVA_MULTIPLIER) & 0xFFFFFF;
    return (low_product + (high_product << 24) + JAVA_ADDEND) & JAVA_MASK;
}

fn ulong java_next_int(ulong* state, ulong bound) {
    if ((bound & (bound - 1)) == 0) {
        state[0] = next_java_state(state[0]);
        return (bound * (state[0] >> 17)) >> 31;
    }
    while (true) {
        state[0] = next_java_state(state[0]);
        ulong bits = state[0] >> 17;
        ulong value = bits % bound;
        if (bits - value + (bound - 1) <= INT32_MAX_VALUE) return value;
    }
    return 0;
}

fn long lottery_scheduling(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("lottery_scheduling") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[1] < 0 || input[1] > (long)MAX_PROCESSES) return -1L;
    usz process_count = (usz)input[1];
    if (input_length != 2 + 3 * process_count) return -1L;

    long[MAX_PROCESSES] process_ids = zeroed;
    long[MAX_PROCESSES] burst_times = zeroed;
    long[MAX_PROCESSES] ticket_counts = zeroed;
    long total_tickets = 0;
    long total_burst_time = 0;
    for (usz index = 0; index < process_count; index++) {
        long process_id = input[2 + 3 * index];
        long burst_time = input[3 + 3 * index];
        long tickets = input[4 + 3 * index];
        if (process_id < 0 || process_id > 32767 || burst_time < 1 || burst_time > 1000 ||
            tickets < 1 || tickets > 1000) return -1L;
        for (usz prior = 0; prior < index; prior++)
            if (process_ids[prior] == process_id) return -1L;
        process_ids[index] = process_id;
        burst_times[index] = burst_time;
        ticket_counts[index] = tickets;
        total_tickets += tickets;
        total_burst_time += burst_time;
    }
    if (total_tickets > 16000 || total_burst_time > 16000) return -1L;

    long seed_scrambled = (input[0] ^ (long)JAVA_MULTIPLIER) & (long)JAVA_MASK;
    ulong random_state = (ulong)seed_scrambled;
    long[48] words = zeroed;
    usz word_count = 0;
    long current_time = 0;
    usz remaining = process_count;
    while (remaining > 0) {
        long current_total_tickets = 0;
        for (usz index = 0; index < remaining; index++) current_total_tickets += ticket_counts[index];
        ulong winning_ticket = java_next_int(&random_state, (ulong)current_total_tickets) + 1;
        ulong cumulative_tickets = 0;
        usz selected = remaining;
        for (usz index = 0; index < remaining; index++) {
            cumulative_tickets += (ulong)ticket_counts[index];
            if (cumulative_tickets >= winning_ticket) { selected = index; break; }
        }
        if (selected == remaining) return -1L;

        long waiting_time = current_time;
        long turnaround_time = waiting_time + burst_times[selected];
        words[word_count++] = process_ids[selected];
        words[word_count++] = waiting_time;
        words[word_count++] = turnaround_time;
        current_time += burst_times[selected];
        for (usz index = selected + 1; index < remaining; index++) {
            process_ids[index - 1] = process_ids[index];
            burst_times[index - 1] = burst_times[index];
            ticket_counts[index - 1] = ticket_counts[index];
        }
        remaining--;
    }

    usz output_bytes = word_count * 8;
    if (output == null || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES) return -2L;
    for (usz index = 0; index < word_count; index++) {
        ulong bits = (ulong)words[index];
        for (usz byte = 0; byte < 8; byte++) {
            output[index * 8 + byte] = (uint8)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}
