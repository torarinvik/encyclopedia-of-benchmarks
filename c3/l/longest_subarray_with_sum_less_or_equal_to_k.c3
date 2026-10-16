module longest_subarray_with_sum_less_or_equal_to_k;

const long INVALID_RESULT = -1;
const long MAX_DOMAIN_VALUE = 2147483647;
const usz MAX_INPUT_LENGTH = 259;

fn long longest_subarray_with_sum_less_or_equal_to_k(long* input, usz length)
    @export("longest_subarray_with_sum_less_or_equal_to_k")
{
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long target = input[0], raw_count = input[1];
    if (target < 0 || target > MAX_DOMAIN_VALUE || raw_count < 0 || raw_count > 256)
        return INVALID_RESULT;
    usz count = (usz)raw_count;
    if (length != count + 2) return INVALID_RESULT;

    long total_sum = 0;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 2];
        if (value < 0 || value > MAX_DOMAIN_VALUE) return INVALID_RESULT;
        total_sum += value;
    }
    if (total_sum > MAX_DOMAIN_VALUE) return INVALID_RESULT;

    usz left = 0, best_length = 0;
    long window_sum = 0;
    for (usz right = 0; right < count; right++) {
        window_sum += input[right + 2];
        while (window_sum > target && left <= right) {
            window_sum -= input[left + 2];
            left++;
        }
        usz current_length = 0;
        if (left <= right) current_length = right - left + 1;
        if (current_length > best_length) best_length = current_length;
    }
    return (long)best_length;
}
