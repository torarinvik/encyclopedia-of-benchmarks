module validate_subsequence;

const usz MAX_PACKED_LENGTH = 8194;

fn long validate_subsequence(long* values, usz length) @export("validate_subsequence")
{
    if (values == null || length < 2 || length > MAX_PACKED_LENGTH || values[0] < 0 || values[0] > 4096 ||
        values[1] < 0 || values[1] > 4096) return -1;
    usz array_length = (usz)values[0];
    usz sequence_length = (usz)values[1];
    if (length != 2 + array_length + sequence_length) return -1;
    for (usz i = 2; i < length; i++)
        if (values[i] < -2147483648 || values[i] > 2147483647) return -1;

    if (array_length == 0) return 0;
    if (sequence_length == 0) return 1;
    usz sequence_start = 2 + array_length;
    usz array_index = 0, sequence_index = 0;
    while (sequence_index < sequence_length && array_index < array_length) {
        if (values[sequence_start + sequence_index] == values[2 + array_index]) sequence_index++;
        array_index++;
    }
    return sequence_index == sequence_length ? 1 : 0;
}
