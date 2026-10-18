/* Deterministic lottery scheduling with the Java Random seeded sequence. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PROCESSES = 16;
constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = 51;
constexpr std::size_t MAX_OUTPUT_BYTES = 384;
constexpr std::uint64_t JAVA_MULTIPLIER = UINT64_C(0x5DEECE66D);
constexpr std::uint64_t JAVA_ADDEND = UINT64_C(0xB);
constexpr std::uint64_t JAVA_MASK = (UINT64_C(1) << 48) - 1;
constexpr std::uint64_t INT32_MAX_VALUE = UINT64_C(0x7FFFFFFF);

std::uint64_t next_java_state(std::uint64_t state) {
    const auto low = state & UINT64_C(0xFFFFFF);
    const auto high = state >> 24;
    const auto low_product = low * JAVA_MULTIPLIER;
    const auto high_product = (high * JAVA_MULTIPLIER) & UINT64_C(0xFFFFFF);
    return (low_product + (high_product << 24) + JAVA_ADDEND) & JAVA_MASK;
}

std::uint64_t java_next_int(std::uint64_t& state, std::uint64_t bound) {
    if ((bound & (bound - 1)) == 0) {
        state = next_java_state(state);
        return (bound * (state >> 17)) >> 31;
    }
    for (;;) {
        state = next_java_state(state);
        const auto bits = state >> 17;
        const auto value = bits % bound;
        if (bits - value + (bound - 1) <= INT32_MAX_VALUE) return value;
    }
}
}  // namespace

extern "C" std::int64_t lottery_scheduling(const std::int64_t* input,
                                             std::size_t input_length,
                                             std::uint8_t* output,
                                             std::size_t output_capacity) {
    if (input == nullptr || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_PROCESSES)) return -1;
    const auto process_count = static_cast<std::size_t>(input[1]);
    if (input_length != 2 + 3 * process_count) return -1;

    std::array<std::int64_t, MAX_PROCESSES> process_ids{};
    std::array<std::int64_t, MAX_PROCESSES> burst_times{};
    std::array<std::int64_t, MAX_PROCESSES> ticket_counts{};
    std::int64_t total_tickets = 0;
    std::int64_t total_burst_time = 0;
    for (std::size_t index = 0; index < process_count; ++index) {
        const auto process_id = input[2 + 3 * index];
        const auto burst_time = input[3 + 3 * index];
        const auto tickets = input[4 + 3 * index];
        if (process_id < 0 || process_id > 32767 || burst_time < 1 || burst_time > 1000 ||
            tickets < 1 || tickets > 1000) return -1;
        for (std::size_t prior = 0; prior < index; ++prior)
            if (process_ids[prior] == process_id) return -1;
        process_ids[index] = process_id;
        burst_times[index] = burst_time;
        ticket_counts[index] = tickets;
        total_tickets += tickets;
        total_burst_time += burst_time;
    }
    if (total_tickets > 16000 || total_burst_time > 16000) return -1;

    std::uint64_t random_state = (static_cast<std::uint64_t>(input[0]) ^ JAVA_MULTIPLIER) & JAVA_MASK;
    std::array<std::int64_t, 3 * MAX_PROCESSES> words{};
    std::size_t word_count = 0;
    std::int64_t current_time = 0;
    std::size_t remaining = process_count;
    while (remaining > 0) {
        std::int64_t current_total_tickets = 0;
        for (std::size_t index = 0; index < remaining; ++index) current_total_tickets += ticket_counts[index];
        const auto winning_ticket = java_next_int(random_state, static_cast<std::uint64_t>(current_total_tickets)) + 1;
        std::uint64_t cumulative_tickets = 0;
        std::size_t selected = remaining;
        for (std::size_t index = 0; index < remaining; ++index) {
            cumulative_tickets += static_cast<std::uint64_t>(ticket_counts[index]);
            if (cumulative_tickets >= winning_ticket) { selected = index; break; }
        }
        if (selected == remaining) return -1;

        const auto waiting_time = current_time;
        const auto turnaround_time = waiting_time + burst_times[selected];
        words[word_count++] = process_ids[selected];
        words[word_count++] = waiting_time;
        words[word_count++] = turnaround_time;
        current_time += burst_times[selected];
        for (std::size_t index = selected + 1; index < remaining; ++index) {
            process_ids[index - 1] = process_ids[index];
            burst_times[index - 1] = burst_times[index];
            ticket_counts[index - 1] = ticket_counts[index];
        }
        --remaining;
    }

    const std::size_t output_bytes = word_count * 8;
    if (output == nullptr || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES) return -2;
    for (std::size_t index = 0; index < word_count; ++index) {
        const auto bits = static_cast<std::uint64_t>(words[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(output_bytes);
}
