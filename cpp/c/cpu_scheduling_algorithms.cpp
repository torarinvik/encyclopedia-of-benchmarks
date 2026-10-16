#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

bool better_choice(std::int64_t mode, std::size_t candidate, std::size_t best,
                   const std::int64_t* arrival, const std::int64_t* burst,
                   const std::int64_t* remaining, const std::int64_t* priority) {
    if (mode == 1)
        return burst[candidate] < burst[best]
            || (burst[candidate] == burst[best]
                && (arrival[candidate] < arrival[best]
                    || (arrival[candidate] == arrival[best] && candidate < best)));
    if (mode == 2)
        return remaining[candidate] < remaining[best]
            || (remaining[candidate] == remaining[best]
                && (arrival[candidate] < arrival[best]
                    || (arrival[candidate] == arrival[best] && candidate < best)));
    return priority[candidate] < priority[best]
        || (priority[candidate] == priority[best] && candidate < best);
}
}

extern "C" std::int64_t cpu_scheduling_algorithms(const std::int64_t* input, std::size_t length,
                                                    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 3 + 4 * 32) return -1;
    const auto mode = input[0], raw_count = input[1], quantum = input[2];
    if (mode < 0 || mode > 5 || raw_count < 0 || raw_count > 32 || quantum < 1 || quantum > 32) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    if (length != 3 + 4 * count) return -1;

    std::int64_t ids[32], arrival[32], burst[32], priority[32], remaining[32];
    std::int64_t completion[32], first_run[32];
    std::size_t order[32];
    for (std::size_t i = 0; i < count; ++i) {
        const auto base = 3 + 4 * i;
        ids[i] = input[base]; arrival[i] = input[base + 1];
        burst[i] = input[base + 2]; priority[i] = input[base + 3];
        if (ids[i] < 0 || ids[i] >= 32 || arrival[i] < 0 || arrival[i] > 256
            || burst[i] < 1 || burst[i] > 32 || priority[i] < -32 || priority[i] > 32) return -1;
        for (std::size_t j = 0; j < i; ++j) if (ids[j] == ids[i]) return -1;
        remaining[i] = burst[i]; completion[i] = -1; first_run[i] = -1; order[i] = i;
    }
    const auto bytes = count * 56;
    if (bytes != 0 && (output == nullptr || capacity < bytes)) return -2;

    if (mode == 0 || mode == 5) {
        for (std::size_t i = 1; i < count; ++i) {
            const auto key = order[i];
            auto j = i;
            while (j > 0 && arrival[order[j - 1]] > arrival[key]) { order[j] = order[j - 1]; --j; }
            order[j] = key;
        }
    }

    std::int64_t time = 0;
    if (mode == 0) {
        for (std::size_t position = 0; position < count; ++position) {
            const auto i = order[position];
            if (time < arrival[i]) time = arrival[i];
            first_run[i] = time; time += burst[i]; completion[i] = time;
        }
    } else if (mode == 1 || mode == 3) {
        std::size_t done = 0;
        while (done < count) {
            auto best = count;
            for (std::size_t i = 0; i < count; ++i) {
                if (completion[i] >= 0 || arrival[i] > time) continue;
                if (best == count || better_choice(mode, i, best, arrival, burst, remaining, priority)) best = i;
            }
            if (best == count) { ++time; continue; }
            first_run[best] = time; time += burst[best]; completion[best] = time; ++done;
        }
    } else if (mode == 2 || mode == 4) {
        std::size_t done = 0;
        while (done < count) {
            auto best = count;
            for (std::size_t i = 0; i < count; ++i) {
                if (remaining[i] <= 0 || arrival[i] > time) continue;
                if (best == count || better_choice(mode, i, best, arrival, burst, remaining, priority)) best = i;
            }
            if (best == count) { ++time; continue; }
            if (first_run[best] < 0) first_run[best] = time;
            --remaining[best]; ++time;
            if (remaining[best] == 0) { completion[best] = time; ++done; }
        }
    } else {
        std::size_t queue[64], head = 0, tail = 0, queue_size = 0, next_arrival = 0, done = 0;
        while (done < count) {
            while (next_arrival < count && arrival[order[next_arrival]] <= time) {
                queue[tail] = order[next_arrival++]; tail = (tail + 1) % 64; ++queue_size;
            }
            if (queue_size == 0) { ++time; continue; }
            const auto current = queue[head]; head = (head + 1) % 64; --queue_size;
            const auto run_for = quantum < remaining[current] ? quantum : remaining[current];
            for (std::int64_t slot = 0; slot < run_for; ++slot) {
                if (first_run[current] < 0) first_run[current] = time;
                --remaining[current]; ++time;
                while (next_arrival < count && arrival[order[next_arrival]] <= time) {
                    queue[tail] = order[next_arrival++]; tail = (tail + 1) % 64; ++queue_size;
                }
            }
            if (remaining[current] > 0) { queue[tail] = current; tail = (tail + 1) % 64; ++queue_size; }
            else { completion[current] = time; ++done; }
        }
    }

    for (std::size_t i = 0; i < count; ++i) {
        const auto turnaround = completion[i] - arrival[i];
        const std::int64_t fields[7] = {ids[i], arrival[i], burst[i], completion[i], turnaround,
                                        turnaround - burst[i], first_run[i] - arrival[i]};
        for (std::size_t field = 0; field < 7; ++field) put_i64_le(output, i * 56 + field * 8, fields[field]);
    }
    return static_cast<std::int64_t>(bytes);
}
