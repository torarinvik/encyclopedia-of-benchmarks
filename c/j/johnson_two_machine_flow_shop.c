#include <stddef.h>
#include <stdint.h>

enum { MAX_JOBS = 8, MAX_TIME = 1000, MAX_INPUT = 1 + 2 * MAX_JOBS };

int64_t johnson_two_machine_flow_shop(const int64_t *input, size_t length) {
    if (!input || length < 1) return -1;
    if (input[0] < 1 || input[0] > MAX_JOBS) return -1;
    const int count = (int)input[0];
    if (length != (size_t)(1 + 2 * count) || length > MAX_INPUT) return -1;

    int64_t first[MAX_JOBS], second[MAX_JOBS];
    int early[MAX_JOBS], late[MAX_JOBS];
    int early_count = 0, late_count = 0;
    for (int job = 0; job < count; ++job) {
        first[job] = input[1 + 2 * job];
        second[job] = input[2 + 2 * job];
        if (first[job] < 0 || first[job] > MAX_TIME || second[job] < 0 || second[job] > MAX_TIME) return -1;
        int *group = first[job] < second[job] ? early : late;
        int *group_count = first[job] < second[job] ? &early_count : &late_count;
        int position = *group_count;
        while (position > 0) {
            const int previous = group[position - 1];
            const int comes_before = first[job] < second[job]
                ? (first[job] < first[previous] || (first[job] == first[previous] && job < previous))
                : (second[job] > second[previous] || (second[job] == second[previous] && job < previous));
            if (!comes_before) break;
            group[position] = previous;
            --position;
        }
        group[position] = job;
        ++*group_count;
    }

    int64_t first_finish = 0, second_finish = 0;
    for (int index = 0; index < early_count + late_count; ++index) {
        const int job = index < early_count ? early[index] : late[index - early_count];
        first_finish += first[job];
        if (second_finish < first_finish) second_finish = first_finish;
        second_finish += second[job];
    }
    return second_finish;
}
