module is_isomorphic;

const MAX_CODEPOINTS = 8;
const MAX_INPUT_LENGTH = 2 + 2 * MAX_CODEPOINTS + 2;

fn long is_isomorphic(long* input, usz length) @export("is_isomorphic") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long source_length = input[0], target_length = input[1];
    if (source_length < 0 || source_length > MAX_CODEPOINTS ||
        target_length < 0 || target_length > MAX_CODEPOINTS) return -1;
    if (length != 2 + (usz)source_length + (usz)target_length) return -1;

    for (usz index = 2; index < length; index++)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (source_length != target_length) return 0;

    long[128] source_to_target, target_to_source;
    for (usz index = 0; index < 128; index++) {
        source_to_target[index] = -1;
        target_to_source[index] = -1;
    }
    for (usz index = 0; index < (usz)source_length; index++) {
        long source = input[2 + index];
        long target = input[2 + (usz)source_length + index];
        if ((source_to_target[(usz)source] != -1 && source_to_target[(usz)source] != target) ||
            (target_to_source[(usz)target] != -1 && target_to_source[(usz)target] != source)) return 0;
        source_to_target[(usz)source] = target;
        target_to_source[(usz)target] = source;
    }
    return 1;
}
