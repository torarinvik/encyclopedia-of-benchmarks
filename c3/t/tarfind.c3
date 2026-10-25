// Bounded clean-room TAR-header filename search benchmark.
// Embench-IoT source declares MIT; see the package attribution.
// SPDX-License-Identifier: MIT
module tarfind;

const int MAX_RECORDS = 35;
const int MAX_QUERIES = 5;
const int MIN_NAME_LENGTH = 5;
const int MAX_NAME_LENGTH = 39;
const int MAX_INPUT_LENGTH = 2 + MAX_RECORDS * (1 + MAX_NAME_LENGTH) +
                             MAX_QUERIES * (1 + MAX_NAME_LENGTH);

fn long tarfind(long* input, usz length, uchar* output, usz capacity)
        @export("tarfind") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_RECORDS ||
        input[1] < 1 || input[1] > MAX_QUERIES) return -1;
    usz record_count = (usz)input[0];
    usz query_count = (usz)input[1];
    usz[MAX_RECORDS] record_offsets, record_lengths;
    usz[MAX_QUERIES] query_offsets, query_lengths;
    uchar[MAX_QUERIES] staged = {};
    usz position = 2;

    for (usz i = 0; i < record_count; i++) {
        if (position >= length) return -1;
        long raw_length = input[position++];
        if (raw_length < MIN_NAME_LENGTH || raw_length > MAX_NAME_LENGTH) return -1;
        usz name_length = (usz)raw_length;
        if (name_length > length - position) return -1;
        record_offsets[i] = position;
        record_lengths[i] = name_length;
        for (usz j = 0; j < name_length; j++) {
            long value = input[position + j];
            if (value < 'A' || value > 'Z') return -1;
        }
        position += name_length;
    }
    for (usz i = 0; i < query_count; i++) {
        if (position >= length) return -1;
        long raw_length = input[position++];
        if (raw_length < MIN_NAME_LENGTH || raw_length > MAX_NAME_LENGTH) return -1;
        usz name_length = (usz)raw_length;
        if (name_length > length - position) return -1;
        query_offsets[i] = position;
        query_lengths[i] = name_length;
        for (usz j = 0; j < name_length; j++) {
            long value = input[position + j];
            if (value < 'A' || value > 'Z') return -1;
        }
        position += name_length;
    }
    if (position != length) return -1;
    if (output == null || capacity < query_count) return -2;

    for (usz q = 0; q < query_count; q++) {
        long found = -1;
        for (usz i = 0; i < record_count; i++) {
            if (record_lengths[i] != query_lengths[q]) continue;
            usz j = 0;
            while (j < query_lengths[q] &&
                   input[record_offsets[i] + j] == input[query_offsets[q] + j]) j++;
            if (j == query_lengths[q]) {
                found = (long)i;
                break;
            }
        }
        staged[q] = found < 0 ? 255 : (uchar)found;
    }
    for (usz q = 0; q < query_count; q++) output[q] = staged[q];
    return (long)query_count;
}
