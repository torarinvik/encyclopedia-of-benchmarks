#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 130;
constexpr std::size_t max_processes = 64;
constexpr std::size_t max_output_bytes = 256;

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value)
{
    auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t sjfscheduling(const std::int32_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto process_count_value = input[0];
    if (process_count_value < 0 || process_count_value > static_cast<std::int32_t>(max_processes)
        || length != 1 + 2 * static_cast<std::size_t>(process_count_value)) return -1;
    const auto process_count = static_cast<std::size_t>(process_count_value);

    std::int32_t arrivals[max_processes], bursts[max_processes], order[max_processes];
    bool completed[max_processes] = {};
    std::size_t cursor = 1;
    for (std::size_t index = 0; index < process_count; ++index) {
        const auto arrival = input[cursor++];
        const auto burst = input[cursor++];
        if (arrival < 0 || arrival > 255 || burst < 1 || burst > 255) return -1;
        arrivals[index] = arrival;
        bursts[index] = burst;
    }

    std::int32_t current_time = 0;
    std::size_t scheduled = 0;
    while (scheduled < process_count) {
        std::size_t best = process_count;
        for (std::size_t index = 0; index < process_count; ++index) {
            if (completed[index] || arrivals[index] > current_time) continue;
            if (best == process_count || bursts[index] < bursts[best]
                || (bursts[index] == bursts[best]
                    && (arrivals[index] < arrivals[best]
                        || (arrivals[index] == arrivals[best] && index < best)))) {
                best = index;
            }
        }
        if (best == process_count) {
            ++current_time;
        } else {
            order[scheduled++] = static_cast<std::int32_t>(best);
            completed[best] = true;
            current_time += bursts[best];
        }
    }

    const auto output_bytes = process_count * 4;
    if (output == nullptr || output_capacity < output_bytes || output_bytes > max_output_bytes) return -2;
    for (std::size_t index = 0; index < process_count; ++index)
        write_i32_le(output, index * 4, order[index]);
    return static_cast<std::int64_t>(output_bytes);
}
