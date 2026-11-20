/* Bounded multi-tape merge with alternating run directions and backward reads. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024
#define MAX_PARTS 2
#define INITIAL_RUN_SIZE 16

static size_t build_run(const int64_t *values, size_t value_count, size_t run_size,
                        size_t merge_inputs, size_t first_run, size_t run_count,
                        bool ascending, int64_t *output)
{
    if (run_count == 1) {
        const size_t start = first_run * run_size;
        size_t length = value_count - start;
        if (length > run_size) length = run_size;
        for (size_t index = 0; index < length; ++index) output[index] = values[start + index];
        for (size_t index = 1; index < length; ++index) {
            const int64_t value = output[index];
            size_t position = index;
            while (position > 0 && (ascending ? value < output[position - 1]
                                              : value > output[position - 1])) {
                output[position] = output[position - 1];
                --position;
            }
            output[position] = value;
        }
        return length;
    }

    int64_t children[MAX_PARTS][MAX_VALUES] = {{0}};
    size_t lengths[MAX_PARTS] = {0};
    size_t positions[MAX_PARTS] = {0};
    const size_t quotient = run_count / merge_inputs;
    const size_t remainder = run_count % merge_inputs;
    size_t next_run = first_run;
    size_t total = 0;
    for (size_t lane = 0; lane < merge_inputs; ++lane) {
        const size_t child_count = quotient + (lane < remainder ? 1 : 0);
        if (child_count == 0) continue;
        lengths[lane] = build_run(values, value_count, run_size, merge_inputs,
                                  next_run, child_count, !ascending, children[lane]);
        next_run += child_count;
        total += lengths[lane];
    }

    for (size_t out = 0; out < total; ++out) {
        size_t best_lane = MAX_PARTS;
        int64_t best_value = 0;
        for (size_t lane = 0; lane < merge_inputs; ++lane) {
            if (positions[lane] >= lengths[lane]) continue;
            const int64_t candidate = children[lane][lengths[lane] - 1 - positions[lane]];
            if (best_lane == MAX_PARTS || (ascending ? candidate < best_value
                                                       : candidate > best_value)) {
                best_lane = lane;
                best_value = candidate;
            }
        }
        output[out] = best_value;
        ++positions[best_lane];
    }
    return total;
}

void oscillating_merge_sort(int64_t *values, size_t length)
{
    if (length > MAX_VALUES || (length != 0 && values == NULL)) return;
    if (length == 0) return;
    int64_t sorted[MAX_VALUES] = {0};
    const size_t run_count = (length + INITIAL_RUN_SIZE - 1) / INITIAL_RUN_SIZE;
    build_run(values, length, INITIAL_RUN_SIZE, MAX_PARTS, 0, run_count, true, sorted);
    for (size_t index = 0; index < length; ++index) values[index] = sorted[index];
}
