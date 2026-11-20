#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define ORS_MAX_Q 32
#define ORS_MAX_TAGS (2 * ORS_MAX_Q)
#define ORS_MAX_ELEMENTS 16
#define ORS_MAX_INPUT (1 + 4 * ORS_MAX_Q)

int64_t observed_remove_set(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > ORS_MAX_INPUT) return -1;
    const int64_t qv = input[0];
    if (qv < 0 || qv > ORS_MAX_Q || length != 1 + (size_t)qv * 4) return -1;
    const size_t q = (size_t)qv;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = input[1 + 4 * i], replica = input[2 + 4 * i];
        const int64_t element = input[3 + 4 * i], peer = input[4 + 4 * i];
        if (op >= 0 && op <= 2) {
            if (replica < 0 || replica > 1 || element < 0 || element >= ORS_MAX_ELEMENTS || peer != 0) return -1;
        } else if (op == 3 || op == 4) {
            if (replica < 0 || replica > 1 || element != 0 || peer < 0 || peer > 1) return -1;
        } else return -1;
    }

    bool used[ORS_MAX_TAGS] = {false};
    int64_t tag_element[ORS_MAX_TAGS] = {0};
    size_t next_sequence[2] = {0, 0};
    bool additions[2][ORS_MAX_TAGS] = {{false}};
    bool removals[2][ORS_MAX_TAGS] = {{false}};
    int64_t answer = 0;
    size_t read_count = 0;

    for (size_t i = 0; i < q; ++i) {
        const int64_t op = input[1 + 4 * i];
        const size_t replica = (size_t)input[2 + 4 * i];
        const int64_t element = input[3 + 4 * i];
        const size_t peer = (size_t)input[4 + 4 * i];
        bool result = false;
        if (op == 0) {
            const size_t tag = replica * ORS_MAX_Q + next_sequence[replica]++;
            used[tag] = true;
            tag_element[tag] = element;
            additions[replica][tag] = true;
        } else if (op == 1) {
            for (size_t tag = 0; tag < ORS_MAX_TAGS; ++tag) {
                if (additions[replica][tag] && !removals[replica][tag] && used[tag] && tag_element[tag] == element)
                    removals[replica][tag] = true;
            }
        } else if (op == 2) {
            for (size_t tag = 0; tag < ORS_MAX_TAGS; ++tag)
                if (additions[replica][tag] && !removals[replica][tag] && used[tag] && tag_element[tag] == element)
                    result = true;
        } else if (op == 3) {
            for (size_t tag = 0; tag < ORS_MAX_TAGS; ++tag) {
                additions[replica][tag] = additions[replica][tag] || additions[peer][tag];
                removals[replica][tag] = removals[replica][tag] || removals[peer][tag];
            }
        } else {
            result = true;
            for (size_t tag = 0; tag < ORS_MAX_TAGS; ++tag)
                if ((additions[replica][tag] && !additions[peer][tag]) ||
                    (removals[replica][tag] && !removals[peer][tag])) result = false;
        }
        if (op == 2 || op == 4) {
            if (result) answer |= INT64_C(1) << read_count;
            ++read_count;
        }
    }
    return answer;
}
