/* Deterministic lottery scheduling with the Java Random seeded sequence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PROCESSES 16
#define MAX_VALID_INPUT_LENGTH (2 + 3 * MAX_PROCESSES)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define MAX_OUTPUT_BYTES (8 * 3 * MAX_PROCESSES)
#define JAVA_MULTIPLIER UINT64_C(0x5DEECE66D)
#define JAVA_ADDEND UINT64_C(0xB)
#define JAVA_MASK ((UINT64_C(1) << 48) - 1)
#define INT32_MAX_VALUE UINT64_C(0x7FFFFFFF)

static uint64_t next_java_state(uint64_t state)
{
    const uint64_t low = state & UINT64_C(0xFFFFFF);
    const uint64_t high = state >> 24;
    const uint64_t low_product = low * JAVA_MULTIPLIER;
    const uint64_t high_product = (high * JAVA_MULTIPLIER) & UINT64_C(0xFFFFFF);
    return (low_product + (high_product << 24) + JAVA_ADDEND) & JAVA_MASK;
}

static uint64_t java_next_int(uint64_t *state, uint64_t bound)
{
    if ((bound & (bound - 1)) == 0) {
        *state = next_java_state(*state);
        return (bound * (*state >> 17)) >> 31;
    }
    for (;;) {
        *state = next_java_state(*state);
        const uint64_t bits = *state >> 17;
        const uint64_t value = bits % bound;
        if (bits - value + (bound - 1) <= INT32_MAX_VALUE) return value;
    }
}

int64_t lottery_scheduling(const int64_t *input, size_t input_length,
                           uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t process_count_value = input[1];
    if (process_count_value < 0 || process_count_value > MAX_PROCESSES) return -1;
    const size_t process_count = (size_t)process_count_value;
    if (input_length != 2 + 3 * process_count) return -1;

    int64_t process_ids[MAX_PROCESSES] = {0};
    int64_t burst_times[MAX_PROCESSES] = {0};
    int64_t ticket_counts[MAX_PROCESSES] = {0};
    int64_t total_tickets = 0;
    int64_t total_burst_time = 0;
    for (size_t index = 0; index < process_count; ++index) {
        const int64_t process_id = input[2 + 3 * index];
        const int64_t burst_time = input[3 + 3 * index];
        const int64_t tickets = input[4 + 3 * index];
        if (process_id < 0 || process_id > 32767 || burst_time < 1 || burst_time > 1000 ||
            tickets < 1 || tickets > 1000) return -1;
        for (size_t prior = 0; prior < index; ++prior)
            if (process_ids[prior] == process_id) return -1;
        process_ids[index] = process_id;
        burst_times[index] = burst_time;
        ticket_counts[index] = tickets;
        total_tickets += tickets;
        total_burst_time += burst_time;
    }
    if (total_tickets > 16000 || total_burst_time > 16000) return -1;

    uint64_t random_state = ((uint64_t)input[0] ^ JAVA_MULTIPLIER) & JAVA_MASK;
    int64_t words[3 * MAX_PROCESSES] = {0};
    size_t word_count = 0;
    int64_t current_time = 0;
    size_t remaining = process_count;
    while (remaining > 0) {
        int64_t current_total_tickets = 0;
        for (size_t index = 0; index < remaining; ++index) current_total_tickets += ticket_counts[index];
        const uint64_t winning_ticket = java_next_int(&random_state, (uint64_t)current_total_tickets) + 1;
        uint64_t cumulative_tickets = 0;
        size_t selected = remaining;
        for (size_t index = 0; index < remaining; ++index) {
            cumulative_tickets += (uint64_t)ticket_counts[index];
            if (cumulative_tickets >= winning_ticket) { selected = index; break; }
        }
        if (selected == remaining) return -1;

        const int64_t waiting_time = current_time;
        const int64_t turnaround_time = waiting_time + burst_times[selected];
        words[word_count++] = process_ids[selected];
        words[word_count++] = waiting_time;
        words[word_count++] = turnaround_time;
        current_time += burst_times[selected];
        for (size_t index = selected + 1; index < remaining; ++index) {
            process_ids[index - 1] = process_ids[index];
            burst_times[index - 1] = burst_times[index];
            ticket_counts[index - 1] = ticket_counts[index];
        }
        --remaining;
    }

    const size_t output_bytes = word_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < word_count; ++index) {
        const uint64_t bits = (uint64_t)words[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)output_bytes;
}
