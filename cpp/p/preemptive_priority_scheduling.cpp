#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_processes = 8;
constexpr std::size_t max_schedule_ticks = 80;
constexpr std::size_t max_output_words = 1 + max_schedule_ticks;

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value)
{
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t preemptive_priority_scheduling(const std::int32_t* input, std::size_t length,
                                                         std::uint8_t* output, std::size_t capacity)
{
    if (input == nullptr || length < 1 || length > 33) return -1;
    const auto process_count = input[0];
    if (process_count < 0 || process_count > static_cast<std::int32_t>(max_processes) ||
        length != 1 + 4 * static_cast<std::size_t>(process_count)) return -1;

    std::array<std::int32_t, max_processes> ids{}, arrivals{}, remaining{}, priorities{};
    std::array<bool, max_processes> seen_ids{};
    for (std::size_t i = 0; i < static_cast<std::size_t>(process_count); ++i) {
        const auto offset = 1 + 4 * i;
        const auto id = input[offset], arrival = input[offset + 1];
        const auto burst = input[offset + 2], priority = input[offset + 3];
        if (id < 0 || id >= static_cast<std::int32_t>(max_processes) || seen_ids[static_cast<std::size_t>(id)] ||
            arrival < 0 || arrival > 16 || burst < 1 || burst > 8) return -1;
        for (std::size_t previous = 0; previous < i; ++previous)
            if (priorities[previous] == priority && arrivals[previous] == arrival) return -1;
        seen_ids[static_cast<std::size_t>(id)] = true;
        ids[i] = id;
        arrivals[i] = arrival;
        remaining[i] = burst;
        priorities[i] = priority;
    }

    std::array<std::int32_t, max_schedule_ticks> schedule{};
    std::size_t tick_count = 0, completed = 0;
    while (completed < static_cast<std::size_t>(process_count)) {
        std::size_t best = static_cast<std::size_t>(process_count);
        for (std::size_t i = 0; i < static_cast<std::size_t>(process_count); ++i) {
            if (remaining[i] <= 0 || arrivals[i] > static_cast<std::int32_t>(tick_count)) continue;
            if (best == static_cast<std::size_t>(process_count) || priorities[i] > priorities[best] ||
                (priorities[i] == priorities[best] && arrivals[i] < arrivals[best])) best = i;
        }
        if (best == static_cast<std::size_t>(process_count)) schedule[tick_count++] = -1;
        else {
            schedule[tick_count++] = ids[best];
            --remaining[best];
            if (remaining[best] == 0) ++completed;
        }
    }

    const auto bytes = (1 + tick_count) * 4;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::uint8_t, max_output_words * 4> buffer{};
    put_i32_le(buffer.data(), 0, static_cast<std::int32_t>(tick_count));
    for (std::size_t i = 0; i < tick_count; ++i) put_i32_le(buffer.data(), 4 * (i + 1), schedule[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
