#include <stddef.h>
#include <stdint.h>

#define AFS_MAX_STRINGS 256
#define AFS_MAX_STRING_LENGTH 32
#define AFS_BUCKET_COUNT 257
#define AFS_MAX_PARSEABLE_LENGTH 8450

static size_t afs_key(const int64_t *input, const size_t *offsets,
                      const size_t *string_lengths, size_t string_index,
                      size_t depth) {
    if (depth >= string_lengths[string_index]) return 0;
    return (size_t)input[offsets[string_index] + depth] + 1;
}

static void afs_sort_indices(const int64_t *input, const size_t *offsets,
                             const size_t *string_lengths, size_t *order,
                             size_t low, size_t high, size_t depth) {
    if (high - low < 2) return;

    size_t counts[AFS_BUCKET_COUNT] = {0};
    size_t starts[AFS_BUCKET_COUNT];
    size_t next[AFS_BUCKET_COUNT];
    for (size_t index = low; index < high; ++index) {
        ++counts[afs_key(input, offsets, string_lengths, order[index], depth)];
    }

    size_t position = low;
    for (size_t bucket = 0; bucket < AFS_BUCKET_COUNT; ++bucket) {
        starts[bucket] = position;
        next[bucket] = position;
        position += counts[bucket];
    }

    for (size_t bucket = 0; bucket < AFS_BUCKET_COUNT; ++bucket) {
        const size_t end = starts[bucket] + counts[bucket];
        while (next[bucket] < end) {
            const size_t current = next[bucket];
            const size_t target_bucket =
                afs_key(input, offsets, string_lengths, order[current], depth);
            if (target_bucket == bucket) {
                ++next[bucket];
            } else {
                const size_t target = next[target_bucket];
                const size_t temporary = order[target];
                order[target] = order[current];
                order[current] = temporary;
                ++next[target_bucket];
            }
        }
    }

    for (size_t bucket = 1; bucket < AFS_BUCKET_COUNT; ++bucket) {
        if (counts[bucket] > 1) {
            afs_sort_indices(input, offsets, string_lengths, order,
                             starts[bucket], starts[bucket] + counts[bucket],
                             depth + 1);
        }
    }
}

int64_t american_flag_string_sorter(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > AFS_MAX_PARSEABLE_LENGTH) {
        return -1;
    }

    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > AFS_MAX_STRINGS) return -1;
    const size_t count = (size_t)count_value;

    size_t offsets[AFS_MAX_STRINGS];
    size_t string_lengths[AFS_MAX_STRINGS];
    size_t order[AFS_MAX_STRINGS];
    size_t position = 1;
    for (size_t index = 0; index < count; ++index) {
        if (position >= length) return -1;
        const int64_t string_length_value = input[position++];
        if (string_length_value < 0
            || string_length_value > AFS_MAX_STRING_LENGTH) {
            return -1;
        }
        const size_t string_length = (size_t)string_length_value;
        if (string_length > length - position) return -1;

        offsets[index] = position;
        string_lengths[index] = string_length;
        order[index] = index;
        for (size_t byte = 0; byte < string_length; ++byte) {
            if (input[position + byte] < 0 || input[position + byte] > 255) {
                return -1;
            }
        }
        position += string_length;
    }
    if (position != length) return -1;

    if (count > 1) {
        afs_sort_indices(input, offsets, string_lengths, order, 0, count, 0);
    }

    int64_t checksum = 0;
    for (size_t rank = 0; rank < count; ++rank) {
        const size_t string_index = order[rank];
        int64_t contribution = (int64_t)string_lengths[string_index] + 1;
        for (size_t byte = 0; byte < string_lengths[string_index]; ++byte) {
            contribution += input[offsets[string_index] + byte] + 1;
        }
        checksum += (int64_t)(rank + 1) * contribution;
    }
    return checksum;
}
