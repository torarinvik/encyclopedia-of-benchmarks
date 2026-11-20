module american_flag_string_sorter;

const AFS_MAX_STRINGS = 256;
const AFS_MAX_STRING_LENGTH = 32;
const AFS_BUCKET_COUNT = 257;
const AFS_MAX_PARSEABLE_LENGTH = 8450;

fn usz afs_key(long* input, usz* offsets, usz* string_lengths,
               usz string_index, usz depth) {
    if (depth >= string_lengths[string_index]) return 0;
    return (usz)input[offsets[string_index] + depth] + 1;
}

fn void afs_sort_indices(long* input, usz* offsets, usz* string_lengths,
                         usz* order, usz low, usz high, usz depth) {
    if (high - low < 2) return;

    usz[AFS_BUCKET_COUNT] counts = {0};
    usz[AFS_BUCKET_COUNT] starts;
    usz[AFS_BUCKET_COUNT] next;
    for (usz index = low; index < high; index += 1) {
        counts[afs_key(input, offsets, string_lengths, order[index], depth)] += 1;
    }

    usz position = low;
    for (usz bucket = 0; bucket < AFS_BUCKET_COUNT; bucket += 1) {
        starts[bucket] = position;
        next[bucket] = position;
        position += counts[bucket];
    }

    for (usz bucket = 0; bucket < AFS_BUCKET_COUNT; bucket += 1) {
        usz end = starts[bucket] + counts[bucket];
        while (next[bucket] < end) {
            usz current = next[bucket];
            usz target_bucket =
                afs_key(input, offsets, string_lengths, order[current], depth);
            if (target_bucket == bucket) {
                next[bucket] += 1;
            } else {
                usz target = next[target_bucket];
                usz temporary = order[target];
                order[target] = order[current];
                order[current] = temporary;
                next[target_bucket] += 1;
            }
        }
    }

    for (usz bucket = 1; bucket < AFS_BUCKET_COUNT; bucket += 1) {
        if (counts[bucket] > 1) {
            afs_sort_indices(input, offsets, string_lengths, order,
                             starts[bucket], starts[bucket] + counts[bucket],
                             depth + 1);
        }
    }
}

fn long american_flag_string_sorter(long* input, usz length)
    @export("american_flag_string_sorter") {
    if (input == null || length < 1 || length > AFS_MAX_PARSEABLE_LENGTH) {
        return -1;
    }

    long count_value = input[0];
    if (count_value < 0 || count_value > AFS_MAX_STRINGS) return -1;
    usz count = (usz)count_value;

    usz[AFS_MAX_STRINGS] offsets = {0};
    usz[AFS_MAX_STRINGS] string_lengths = {0};
    usz[AFS_MAX_STRINGS] order = {0};
    usz position = 1;
    for (usz index = 0; index < count; index += 1) {
        if (position >= length) return -1;
        long string_length_value = input[position++];
        if (string_length_value < 0
            || string_length_value > AFS_MAX_STRING_LENGTH) {
            return -1;
        }
        usz string_length = (usz)string_length_value;
        if (string_length > length - position) return -1;

        offsets[index] = position;
        string_lengths[index] = string_length;
        order[index] = index;
        for (usz byte = 0; byte < string_length; byte += 1) {
            if (input[position + byte] < 0 || input[position + byte] > 255) {
                return -1;
            }
        }
        position += string_length;
    }
    if (position != length) return -1;

    if (count > 1) {
        afs_sort_indices(input, &offsets[0], &string_lengths[0], &order[0],
                         0, count, 0);
    }

    long checksum = 0;
    for (usz rank = 0; rank < count; rank += 1) {
        usz string_index = order[rank];
        long contribution = (long)string_lengths[string_index] + 1;
        for (usz byte = 0; byte < string_lengths[string_index]; byte += 1) {
            contribution += input[offsets[string_index] + byte] + 1;
        }
        checksum += (long)(rank + 1) * contribution;
    }
    return checksum;
}
