#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_JOBS 128
#define MAX_INPUT_LENGTH (1 + 4 * MAX_JOBS)
#define MAX_DEADLINE 32
#define MAX_ID INT64_C(2147483647)
#define MAX_PROFIT INT64_C(1000000)
#define PACK_BASE INT64_C(4294967296)

int64_t job_scheduling_with_deadline(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = packed[0];
    if (count_value < 0 || count_value > MAX_JOBS ||
        length != 1 + (size_t)count_value * 4) return -1;
    const size_t count = (size_t)count_value;

    int64_t ids[MAX_JOBS] = {0};
    int64_t arrivals[MAX_JOBS] = {0};
    int64_t deadlines[MAX_JOBS] = {0};
    int64_t profits[MAX_JOBS] = {0};
    int64_t max_deadline = 0;
    for (size_t i = 0; i < count; ++i) {
        const size_t base = 1 + i * 4;
        ids[i] = packed[base];
        arrivals[i] = packed[base + 1];
        deadlines[i] = packed[base + 2];
        profits[i] = packed[base + 3];
        if (ids[i] < 0 || ids[i] > MAX_ID ||
            arrivals[i] < 1 || arrivals[i] > MAX_DEADLINE ||
            deadlines[i] < 1 || deadlines[i] > MAX_DEADLINE ||
            profits[i] < -MAX_PROFIT || profits[i] > MAX_PROFIT) return -1;
        for (size_t previous = 0; previous < i; ++previous)
            if (ids[previous] == ids[i]) return -1;
        if (deadlines[i] > max_deadline) max_deadline = deadlines[i];
    }

    /* Stable insertion sort: equal-profit jobs retain their input order. */
    for (size_t i = 1; i < count; ++i) {
        const int64_t key_id = ids[i];
        const int64_t key_arrival = arrivals[i];
        const int64_t key_deadline = deadlines[i];
        const int64_t key_profit = profits[i];
        size_t position = i;
        while (position > 0 && profits[position - 1] < key_profit) {
            ids[position] = ids[position - 1];
            arrivals[position] = arrivals[position - 1];
            deadlines[position] = deadlines[position - 1];
            profits[position] = profits[position - 1];
            --position;
        }
        ids[position] = key_id;
        arrivals[position] = key_arrival;
        deadlines[position] = key_deadline;
        profits[position] = key_profit;
    }

    bool occupied[MAX_DEADLINE] = {false};
    int64_t scheduled = 0;
    int64_t total_profit = 0;
    for (size_t i = 0; i < count; ++i) {
        if (arrivals[i] > deadlines[i]) continue;
        const int64_t last_slot = deadlines[i] - 1 < max_deadline - 1
            ? deadlines[i] - 1 : max_deadline - 1;
        for (int64_t slot = last_slot; slot >= arrivals[i] - 1; --slot) {
            if (!occupied[(size_t)slot]) {
                occupied[(size_t)slot] = true;
                ++scheduled;
                total_profit += profits[i];
                break;
            }
        }
    }

    int64_t low_word = total_profit;
    if (low_word < 0) low_word += PACK_BASE;
    return scheduled * PACK_BASE + low_word;
}
