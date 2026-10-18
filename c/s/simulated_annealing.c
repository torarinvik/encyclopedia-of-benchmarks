#include <stddef.h>
#include <stdint.h>

#define MAX_PACKED_LENGTH 366
#define MAX_DRAWS 176
#define MAX_ITERATIONS 22
#define INVALID_RESULT (-INT64_C(1))

static int64_t score_i64(int64_t x, int64_t y)
{
    return x * x + y * y;
}

int64_t simulated_annealing(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 13 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;

    const int64_t x0 = packed[0], y0 = packed[1], step = packed[2];
    const int64_t min_x = packed[3], max_x = packed[4];
    const int64_t min_y = packed[5], max_y = packed[6];
    const int64_t find_max = packed[7];
    const int64_t start_raw = packed[8], rate_raw = packed[9], threshold_raw = packed[10];
    const int64_t selection_count = packed[11];
    if (x0 < -16 || x0 > 16 || y0 < -16 || y0 > 16 ||
        step < 1 || step > 4 || min_x < -16 || max_x > 16 || min_x > max_x ||
        min_y < -16 || max_y > 16 || min_y > max_y ||
        x0 < min_x || x0 > max_x || y0 < min_y || y0 > max_y ||
        (find_max != 0 && find_max != 1) ||
        start_raw < 1000000 || start_raw > 10000000 ||
        rate_raw < 100000 || rate_raw > 500000 ||
        threshold_raw < 1000000 || threshold_raw > 9999999 || threshold_raw >= start_raw ||
        selection_count < 0 || selection_count > MAX_DRAWS ||
        selection_count > (int64_t)(length - 13)) return INVALID_RESULT;

    const size_t selection_n = (size_t)selection_count;
    const size_t acceptance_count_index = 12 + selection_n;
    const int64_t acceptance_count = packed[acceptance_count_index];
    if (acceptance_count < 0 || acceptance_count > MAX_DRAWS ||
        length != 13 + selection_n + (size_t)acceptance_count) return INVALID_RESULT;
    for (size_t i = 0; i < selection_n; ++i) {
        if (packed[12 + i] < 0 || packed[12 + i] > 7) return INVALID_RESULT;
    }
    const size_t acceptance_start = acceptance_count_index + 1;
    for (size_t i = 0; i < (size_t)acceptance_count; ++i) {
        const int64_t draw = packed[acceptance_start + i];
        if (draw != 0 && draw != 999999) return INVALID_RESULT;
    }

    double current_temp = (double)start_raw / 1000000.0;
    const double rate = (double)rate_raw / 1000000.0;
    const double threshold = (double)threshold_raw / 1000000.0;
    int64_t current_x = x0, current_y = y0;
    int64_t best_x = x0, best_y = y0;
    int64_t best_score = score_i64(x0, y0);
    size_t selection_cursor = 0, acceptance_cursor = 0;
    int stopped = 0;

    for (int iteration = 0; iteration < MAX_ITERATIONS; ++iteration) {
        const int64_t current_score = score_i64(current_x, current_y);
        if (current_score > best_score) {
            best_score = current_score;
            best_x = current_x;
            best_y = current_y;
        }

        int64_t neighbor_x[8] = {
            current_x-step, current_x-step, current_x-step, current_x,
            current_x, current_x+step, current_x+step, current_x+step
        };
        int64_t neighbor_y[8] = {
            current_y-step, current_y, current_y+step, current_y-step,
            current_y+step, current_y-step, current_y, current_y+step
        };
        size_t remaining = 8;
        int found = 0;
        int64_t next_x = 0, next_y = 0;

        while (!found && remaining > 0) {
            if (selection_cursor >= selection_n) return INVALID_RESULT;
            const int64_t rank = packed[12 + selection_cursor++];
            if ((size_t)rank >= remaining) return INVALID_RESULT;
            const size_t selected = (size_t)rank;
            const int64_t candidate_x = neighbor_x[selected];
            const int64_t candidate_y = neighbor_y[selected];
            const int64_t raw_change = score_i64(candidate_x, candidate_y) - current_score;
            for (size_t i = selected + 1; i < remaining; ++i) {
                neighbor_x[i - 1] = neighbor_x[i];
                neighbor_y[i - 1] = neighbor_y[i];
            }
            --remaining;

            if (candidate_x < min_x || candidate_x > max_x ||
                candidate_y < min_y || candidate_y > max_y) continue;
            const int64_t change = find_max ? raw_change : -raw_change;
            if (change > 0) {
                found = 1;
            } else {
                if (acceptance_cursor >= (size_t)acceptance_count) return INVALID_RESULT;
                const int64_t draw = packed[acceptance_start + acceptance_cursor++];
                if (change == 0 || draw == 0) found = 1;
            }
            if (found) {
                next_x = candidate_x;
                next_y = candidate_y;
            }
        }

        current_temp = current_temp - current_temp * rate;
        if (current_temp < threshold || !found) {
            stopped = 1;
            break;
        }
        current_x = next_x;
        current_y = next_y;
    }
    if (!stopped) return INVALID_RESULT;
    return (best_x + 16) * 33 + (best_y + 16);
}
