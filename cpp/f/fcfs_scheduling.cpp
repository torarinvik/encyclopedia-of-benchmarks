#include <cstddef>
#include <cstdint>

static void store_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

extern "C" std::int64_t fcfs_scheduling(const std::int64_t *values, std::size_t length,
                                          std::uint8_t *output,
                                          std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 193) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 3 * count) return -2;

    std::int64_t ids[64], arrivals[64], bursts[64];
    std::size_t order[64];
    for (std::size_t i = 0; i < count; ++i) {
        const auto id = values[1 + 3 * i];
        const auto arrival = values[2 + 3 * i];
        const auto burst = values[3 + 3 * i];
        if (id < 0 || id > 63 || arrival < 0 || arrival > 1000000 || burst < 1 || burst > 1000000)
            return -2;
        for (std::size_t previous = 0; previous < i; ++previous)
            if (ids[previous] == id) return -2;
        ids[i] = id;
        arrivals[i] = arrival;
        bursts[i] = burst;
        order[i] = i;
    }
    for (std::size_t i = 1; i < count; ++i) {
        const auto key = order[i];
        auto j = i;
        while (j > 0 && (arrivals[order[j - 1]] > arrivals[key] ||
               (arrivals[order[j - 1]] == arrivals[key] && ids[order[j - 1]] > ids[key]))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }

    const auto required = count * 48;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    std::int64_t elapsed = 0;
    for (std::size_t position = 0; position < count; ++position) {
        const auto i = order[position];
        if (elapsed < arrivals[i]) elapsed = arrivals[i];
        const auto completion = elapsed + bursts[i];
        const auto turnaround = completion - arrivals[i];
        const auto waiting = turnaround - bursts[i];
        const std::int64_t fields[6] = {ids[i], arrivals[i], bursts[i], completion, turnaround, waiting};
        for (std::size_t field = 0; field < 6; ++field)
            store_i64_le(output, position * 48 + field * 8, fields[field]);
        elapsed = completion;
    }
    return static_cast<std::int64_t>(count);
}
