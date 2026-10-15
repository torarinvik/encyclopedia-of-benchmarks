module detect_anagrams;

const MAX_TEXT_LENGTH = 16;
const MAX_CANDIDATE_COUNT = 16;
const MAX_INPUT_LENGTH = 290;

fn bool is_ascii_letter(long value) {
    return (value >= 65 && value <= 90) || (value >= 97 && value <= 122);
}

fn long lowercase_ascii(long value) {
    return value >= 65 && value <= 90 ? value + 32 : value;
}

fn usz letter_index(long value) {
    return (usz)(value >= 65 && value <= 90 ? value - 65 : value - 97);
}

fn long detect_anagrams(long* input, usz length, char* output, usz capacity)
        @export("detect_anagrams") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT_LENGTH) return -1;
    usz subject_length = (usz)input[0];
    usz subject_start = 1;
    usz position = subject_start + subject_length;
    if (position >= length) return -1;
    long candidate_count_value = input[position++];
    if (candidate_count_value < 0 || candidate_count_value > MAX_CANDIDATE_COUNT) return -1;
    usz candidate_count = (usz)candidate_count_value;

    usz[26] subject_counts;
    for (usz letter = 0; letter < 26; letter++) subject_counts[letter] = 0;
    for (usz offset = 0; offset < subject_length; offset++) {
        long value = input[subject_start + offset];
        if (!is_ascii_letter(value)) return -1;
        subject_counts[letter_index(value)]++;
    }

    usz[MAX_CANDIDATE_COUNT] match_starts;
    usz[MAX_CANDIDATE_COUNT] match_lengths;
    usz match_count = 0;
    usz required = 1;
    for (usz candidate = 0; candidate < candidate_count; candidate++) {
        if (position >= length) return -1;
        long candidate_length_value = input[position++];
        if (candidate_length_value < 0 || candidate_length_value > MAX_TEXT_LENGTH) return -1;
        usz candidate_length = (usz)candidate_length_value;
        if (candidate_length > length - position) return -1;
        usz candidate_start = position;

        usz[26] candidate_counts;
        for (usz letter = 0; letter < 26; letter++) candidate_counts[letter] = 0;
        bool identical = candidate_length == subject_length;
        for (usz offset = 0; offset < candidate_length; offset++) {
            long value = input[candidate_start + offset];
            if (!is_ascii_letter(value)) return -1;
            candidate_counts[letter_index(value)]++;
            if (identical && lowercase_ascii(value) != lowercase_ascii(input[subject_start + offset])) {
                identical = false;
            }
        }

        bool same_signature = true;
        for (usz letter = 0; letter < 26; letter++) {
            if (candidate_counts[letter] != subject_counts[letter]) same_signature = false;
        }
        if (same_signature && !identical) {
            match_starts[match_count] = candidate_start;
            match_lengths[match_count] = candidate_length;
            match_count++;
            required += candidate_length + 1;
        }
        position += candidate_length;
    }
    if (position != length) return -1;
    if (output == null || capacity < required) return -2;

    usz written = 0;
    for (usz match = 0; match < match_count; match++) {
        for (usz offset = 0; offset < match_lengths[match]; offset++) {
            output[written++] = (char)input[match_starts[match] + offset];
        }
        output[written++] = '\n';
    }
    output[written] = 0;
    return (long)match_count;
}
