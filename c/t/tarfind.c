/* Bounded clean-room TAR-header filename search benchmark.
 * The Embench-IoT tarfind source declares MIT; see its attribution package.
 */
/* SPDX-License-Identifier: MIT */
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_RECORDS = 35,
    MAX_QUERIES = 5,
    MIN_NAME_LENGTH = 5,
    MAX_NAME_LENGTH = 39,
    MAX_INPUT_LENGTH = 2 + MAX_RECORDS * (1 + MAX_NAME_LENGTH) +
                       MAX_QUERIES * (1 + MAX_NAME_LENGTH)
};

int64_t tarfind(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    size_t record_offsets[MAX_RECORDS], record_lengths[MAX_RECORDS];
    size_t query_offsets[MAX_QUERIES], query_lengths[MAX_QUERIES];
    uint8_t staged[MAX_QUERIES];
    size_t position = 2;

    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_RECORDS ||
        input[1] < 1 || input[1] > MAX_QUERIES) return -1;
    const size_t record_count = (size_t)input[0];
    const size_t query_count = (size_t)input[1];

    for (size_t i = 0; i < record_count; ++i) {
        if (position >= length) return -1;
        const int64_t raw_length = input[position++];
        if (raw_length < MIN_NAME_LENGTH || raw_length > MAX_NAME_LENGTH) return -1;
        const size_t name_length = (size_t)raw_length;
        if (name_length > length - position) return -1;
        record_offsets[i] = position;
        record_lengths[i] = name_length;
        for (size_t j = 0; j < name_length; ++j)
            if (input[position + j] < 'A' || input[position + j] > 'Z') return -1;
        position += name_length;
    }
    for (size_t i = 0; i < query_count; ++i) {
        if (position >= length) return -1;
        const int64_t raw_length = input[position++];
        if (raw_length < MIN_NAME_LENGTH || raw_length > MAX_NAME_LENGTH) return -1;
        const size_t name_length = (size_t)raw_length;
        if (name_length > length - position) return -1;
        query_offsets[i] = position;
        query_lengths[i] = name_length;
        for (size_t j = 0; j < name_length; ++j)
            if (input[position + j] < 'A' || input[position + j] > 'Z') return -1;
        position += name_length;
    }
    if (position != length) return -1;
    if (output == NULL || capacity < query_count) return -2;

    for (size_t q = 0; q < query_count; ++q) {
        int64_t found = -1;
        for (size_t i = 0; i < record_count; ++i) {
            if (record_lengths[i] != query_lengths[q]) continue;
            size_t j = 0;
            while (j < query_lengths[q] &&
                   input[record_offsets[i] + j] == input[query_offsets[q] + j]) ++j;
            if (j == query_lengths[q]) {
                found = (int64_t)i;
                break;
            }
        }
        staged[q] = found < 0 ? UINT8_MAX : (uint8_t)found;
    }
    for (size_t q = 0; q < query_count; ++q) output[q] = staged[q];
    return (int64_t)query_count;
}
