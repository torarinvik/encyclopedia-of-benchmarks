#include <cstddef>
#include <cstdint>

static void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t mlfqscheduler(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 55) return -1;
    const auto levels_value = input[0], process_count_value = input[1];
    if (levels_value < 1 || levels_value > 4 || process_count_value < 0 || process_count_value > 16) return -1;
    const auto levels = static_cast<std::size_t>(levels_value), process_count = static_cast<std::size_t>(process_count_value);
    if (length != 2 + levels + 3 * process_count) return -1;
    std::int64_t quanta[4]{}, pids[16]{}, remaining[16]{};
    for (std::size_t level = 0; level < levels; ++level) {
        quanta[level] = input[2 + level];
        if (quanta[level] < 1 || quanta[level] > 32) return -1;
    }
    const std::size_t process_offset = 2 + levels;
    for (std::size_t i = 0; i < process_count; ++i) {
        const auto pid = input[process_offset + 3 * i];
        const auto burst = input[process_offset + 3 * i + 1];
        const auto arrival = input[process_offset + 3 * i + 2];
        if (pid < INT32_MIN || pid > INT32_MAX || burst < 0 || burst > 1000 || arrival < 0 || arrival > 1000000) return -1;
        pids[i] = pid; remaining[i] = burst;
    }

    std::size_t queues[64]{}, queue_counts[4]{};
    for (std::size_t i = 0; i < process_count; ++i) queues[i] = i;
    queue_counts[0] = process_count;
    std::int64_t completion_pids[16]{}, completion_times[16]{};
    std::size_t completions = 0;
    std::int64_t current_time = 0;
    for (;;) {
        std::size_t active = 0;
        for (std::size_t level = 0; level < levels; ++level) active += queue_counts[level];
        if (active == 0) break;
        for (std::size_t level = 0; level < levels; ++level) {
            const std::size_t base = level * 16, queued = queue_counts[level];
            if (queued == 0) continue;
            const std::size_t process = queues[base];
            for (std::size_t j = 1; j < queued; ++j) queues[base + j - 1] = queues[base + j];
            --queue_counts[level];
            const auto slice = quanta[level] < remaining[process] ? quanta[level] : remaining[process];
            current_time += slice;
            remaining[process] -= slice;
            if (remaining[process] == 0) {
                completion_pids[completions] = pids[process]; completion_times[completions++] = current_time;
            } else {
                const auto destination = level + 1 < levels ? level + 1 : level;
                queues[destination * 16 + queue_counts[destination]++] = process;
            }
        }
    }

    const std::size_t elements = 2 + 2 * completions, required = elements * 8;
    if (output == nullptr || output_capacity < required) return -2;
    put_i64_le(output, 0, current_time); put_i64_le(output, 8, static_cast<std::int64_t>(completions));
    for (std::size_t i = 0; i < completions; ++i) {
        put_i64_le(output, 16 + 16 * i, completion_pids[i]);
        put_i64_le(output, 24 + 16 * i, completion_times[i]);
    }
    return static_cast<std::int64_t>(elements);
}
