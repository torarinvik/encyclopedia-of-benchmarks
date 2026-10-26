#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_QUEUES = 4, MAX_SLOTS = 8, MAX_INPUT = 36, MAX_OUTPUT_BYTES = 64;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t packet_switching_sgr_multi_queue(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > MAX_INPUT) return -1;
    const auto queue_value = input[0], buffer_value = input[1], slot_value = input[2];
    if (queue_value < 2 || queue_value > static_cast<std::int64_t>(MAX_QUEUES) ||
        buffer_value < 1 || buffer_value > 4 || slot_value < 1 || slot_value > static_cast<std::int64_t>(MAX_SLOTS)) return -1;
    const auto queues = static_cast<std::size_t>(queue_value), slots = static_cast<std::size_t>(slot_value);
    const auto buffer = buffer_value;
    if (length != 3 + queues * slots) return -1;
    std::array<std::int64_t, MAX_QUEUES> load{}, peak{};
    std::array<std::int64_t, MAX_SLOTS> schedule{};
    for (std::size_t slot = 0; slot < slots; ++slot) {
        for (std::size_t queue = 0; queue < queues; ++queue) {
            const auto arrivals = input[3 + slot * queues + queue];
            if (arrivals < 0 || arrivals > buffer) return -1;
            load[queue] += arrivals;
            if (load[queue] > buffer) load[queue] = buffer;
            if (load[queue] > peak[queue]) peak[queue] = load[queue];
        }
        bool has_large = false, has_nonempty = false, has_underfull_peak = false;
        for (std::size_t queue = 0; queue < queues; ++queue) if (load[queue] > 0) {
            has_nonempty = true;
            if (load[queue] > buffer / 2) has_large = true;
            if (peak[queue] < buffer) has_underfull_peak = true;
        }
        if (!has_nonempty) {
            schedule[slot] = -1;
            peak.fill(0);
            continue;
        }
        const bool use_history = !has_large && has_underfull_peak;
        std::size_t selected = queues;
        for (std::size_t queue = 0; queue < queues; ++queue) {
            if (load[queue] == 0 || (use_history && peak[queue] >= buffer)) continue;
            if (selected == queues || load[queue] > load[selected]) selected = queue;
        }
        schedule[slot] = static_cast<std::int64_t>(selected);
        --load[selected];
        bool any_left = false;
        for (std::size_t queue = 0; queue < queues; ++queue) any_left |= load[queue] > 0;
        if (!any_left) peak.fill(0);
    }
    const std::size_t output_bytes = 8 * slots;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::array<std::uint8_t, MAX_OUTPUT_BYTES> staged{};
    for (std::size_t slot = 0; slot < slots; ++slot) store_i64_le(staged.data(), 8 * slot, schedule[slot]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
