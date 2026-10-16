#include <stddef.h>
#include <stdint.h>

static void put_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int better_choice(int64_t mode, size_t candidate, size_t best,
                         const int64_t *arrival, const int64_t *burst,
                         const int64_t *remaining, const int64_t *priority)
{
    if (mode == 1) {
        return burst[candidate] < burst[best]
            || (burst[candidate] == burst[best]
                && (arrival[candidate] < arrival[best]
                    || (arrival[candidate] == arrival[best] && candidate < best)));
    }
    if (mode == 2) {
        return remaining[candidate] < remaining[best]
            || (remaining[candidate] == remaining[best]
                && (arrival[candidate] < arrival[best]
                    || (arrival[candidate] == arrival[best] && candidate < best)));
    }
    return priority[candidate] < priority[best]
        || (priority[candidate] == priority[best] && candidate < best);
}

int64_t cpu_scheduling_algorithms(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > 3 + 4 * 32) return -1;
    const int64_t mode = input[0];
    const int64_t raw_count = input[1];
    const int64_t quantum = input[2];
    if (mode < 0 || mode > 5 || raw_count < 0 || raw_count > 32
        || quantum < 1 || quantum > 32) return -1;
    const size_t count = (size_t)raw_count;
    if (length != 3 + 4 * count) return -1;

    int64_t ids[32], arrival[32], burst[32], priority[32], remaining[32];
    int64_t completion[32], first_run[32];
    size_t order[32];
    for (size_t i = 0; i < count; ++i) {
        const size_t base = 3 + 4 * i;
        ids[i] = input[base];
        arrival[i] = input[base + 1];
        burst[i] = input[base + 2];
        priority[i] = input[base + 3];
        if (ids[i] < 0 || ids[i] >= 32 || arrival[i] < 0 || arrival[i] > 256
            || burst[i] < 1 || burst[i] > 32 || priority[i] < -32 || priority[i] > 32)
            return -1;
        for (size_t j = 0; j < i; ++j) if (ids[j] == ids[i]) return -1;
        remaining[i] = burst[i];
        completion[i] = -1;
        first_run[i] = -1;
        order[i] = i;
    }

    const size_t bytes = count * 56;
    if (bytes != 0 && (output == NULL || capacity < bytes)) return -2;

    if (mode == 0 || mode == 5) {
        for (size_t i = 1; i < count; ++i) {
            const size_t key = order[i];
            size_t j = i;
            while (j > 0 && arrival[order[j - 1]] > arrival[key]) {
                order[j] = order[j - 1];
                --j;
            }
            order[j] = key;
        }
    }

    int64_t time = 0;
    if (mode == 0) {
        for (size_t position = 0; position < count; ++position) {
            const size_t i = order[position];
            if (time < arrival[i]) time = arrival[i];
            first_run[i] = time;
            time += burst[i];
            completion[i] = time;
        }
    } else if (mode == 1 || mode == 3) {
        size_t done = 0;
        while (done < count) {
            size_t best = count;
            for (size_t i = 0; i < count; ++i) {
                if (completion[i] >= 0 || arrival[i] > time) continue;
                if (best == count || better_choice(mode, i, best, arrival, burst, remaining, priority))
                    best = i;
            }
            if (best == count) { ++time; continue; }
            first_run[best] = time;
            time += burst[best];
            completion[best] = time;
            ++done;
        }
    } else if (mode == 2 || mode == 4) {
        size_t done = 0;
        while (done < count) {
            size_t best = count;
            for (size_t i = 0; i < count; ++i) {
                if (remaining[i] <= 0 || arrival[i] > time) continue;
                if (best == count || better_choice(mode, i, best, arrival, burst, remaining, priority))
                    best = i;
            }
            if (best == count) { ++time; continue; }
            if (first_run[best] < 0) first_run[best] = time;
            --remaining[best];
            ++time;
            if (remaining[best] == 0) { completion[best] = time; ++done; }
        }
    } else {
        size_t queue[64], head = 0, tail = 0, queue_size = 0, next_arrival = 0, done = 0;
        while (done < count) {
            while (next_arrival < count && arrival[order[next_arrival]] <= time) {
                queue[tail] = order[next_arrival++];
                tail = (tail + 1) % 64;
                ++queue_size;
            }
            if (queue_size == 0) { ++time; continue; }
            const size_t current = queue[head];
            head = (head + 1) % 64;
            --queue_size;
            const int64_t run_for = quantum < remaining[current] ? quantum : remaining[current];
            for (int64_t slot = 0; slot < run_for; ++slot) {
                if (first_run[current] < 0) first_run[current] = time;
                --remaining[current];
                ++time;
                while (next_arrival < count && arrival[order[next_arrival]] <= time) {
                    queue[tail] = order[next_arrival++];
                    tail = (tail + 1) % 64;
                    ++queue_size;
                }
            }
            if (remaining[current] > 0) {
                queue[tail] = current;
                tail = (tail + 1) % 64;
                ++queue_size;
            } else {
                completion[current] = time;
                ++done;
            }
        }
    }

    for (size_t i = 0; i < count; ++i) {
        const int64_t turnaround = completion[i] - arrival[i];
        const int64_t waiting = turnaround - burst[i];
        const int64_t response = first_run[i] - arrival[i];
        const int64_t fields[7] = {ids[i], arrival[i], burst[i], completion[i],
                                   turnaround, waiting, response};
        for (size_t field = 0; field < 7; ++field)
            put_i64_le(output, i * 56 + field * 8, fields[field]);
    }
    return (int64_t)bytes;
}
