#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PACKETS = 16, MAX_SLOTS = 8, MAX_INPUT = 38, MAX_OUTPUT_BYTES = 64;
constexpr std::int64_t BETA = 15;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
template <std::size_t N>
void erase_pair(std::array<std::int64_t, N>& ids, std::array<std::int64_t, N>& values,
        std::size_t& count, std::size_t index) {
    for (std::size_t position = index; position + 1 < count; ++position) {
        ids[position] = ids[position + 1];
        values[position] = values[position + 1];
    }
    --count;
}
}

extern "C" std::int64_t packet_switching_single_buffer(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 5 || length > MAX_INPUT) return -1;
    const auto mode = input[0], buffer_value = input[1], beta = input[2], slots_value = input[3], count_value = input[4];
    if (mode < 0 || mode > 2 || buffer_value < 1 || buffer_value > 4 || slots_value < 1 || slots_value > static_cast<std::int64_t>(MAX_SLOTS) ||
        count_value < 0 || count_value > static_cast<std::int64_t>(MAX_PACKETS) || length != 5 + 2 * static_cast<std::size_t>(count_value) ||
        (mode == 0 ? beta != 0 : beta != BETA)) return -1;
    const auto slots = static_cast<std::size_t>(slots_value), packet_count = static_cast<std::size_t>(count_value);
    std::array<std::int64_t, MAX_PACKETS> arrival{}, packet_value{};
    std::int64_t previous_slot = -1;
    for (std::size_t packet = 0; packet < packet_count; ++packet) {
        arrival[packet] = input[5 + 2 * packet]; packet_value[packet] = input[6 + 2 * packet];
        if (arrival[packet] < 0 || arrival[packet] >= slots_value || arrival[packet] < previous_slot || packet_value[packet] < 1 || packet_value[packet] > 100) return -1;
        previous_slot = arrival[packet];
    }
    std::array<std::int64_t, MAX_PACKETS> resident_id{}, resident_value{};
    std::array<std::int64_t, MAX_SLOTS> schedule{};
    std::size_t resident_count = 0, next_packet = 0;
    for (std::size_t slot = 0; slot < slots; ++slot) {
        while (next_packet < packet_count && arrival[next_packet] == static_cast<std::int64_t>(slot)) {
            const auto value = packet_value[next_packet];
            std::size_t preempt = resident_count;
            if (mode == 1) {
                for (std::size_t i = 0; i < resident_count; ++i) if (resident_value[i] * BETA <= value) { preempt = i; break; }
            } else if (mode == 2) {
                for (std::size_t i = 0; i < resident_count; ++i) {
                    const bool following_ok = i + 1 == resident_count || resident_value[i] <= resident_value[i + 1];
                    if (resident_value[i] * BETA < value && following_ok) { preempt = i; break; }
                }
            }
            if (preempt < resident_count) {
                erase_pair(resident_id, resident_value, resident_count, preempt);
                resident_id[resident_count] = static_cast<std::int64_t>(next_packet); resident_value[resident_count++] = value;
            } else if (resident_count < static_cast<std::size_t>(buffer_value)) {
                resident_id[resident_count] = static_cast<std::int64_t>(next_packet); resident_value[resident_count++] = value;
            } else {
                std::int64_t smallest = resident_value[0];
                for (std::size_t i = 1; i < resident_count; ++i) if (resident_value[i] < smallest) smallest = resident_value[i];
                if (value > smallest) {
                    std::size_t evict = 0; while (resident_value[evict] != smallest) ++evict;
                    erase_pair(resident_id, resident_value, resident_count, evict);
                    resident_id[resident_count] = static_cast<std::int64_t>(next_packet); resident_value[resident_count++] = value;
                }
            }
            ++next_packet;
        }
        if (resident_count) { schedule[slot] = resident_id[0]; erase_pair(resident_id, resident_value, resident_count, 0); }
        else schedule[slot] = -1;
    }
    const std::size_t output_bytes = 8 * slots;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::array<std::uint8_t, MAX_OUTPUT_BYTES> staged{};
    for (std::size_t slot = 0; slot < slots; ++slot) store_i64_le(staged.data(), 8 * slot, schedule[slot]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
