module power_sort;

const usz MAX_VALUES = 64;
const usz MAX_INPUT_VALUES = 67;
const long MIN_VALUE = -1000000L;
const long MAX_VALUE = 1000000L;

struct Run { usz start; usz length; long power; }

fn bool key_less(long left, long right, bool reverse) {
    return reverse ? left > right : left < right;
}

fn usz find_run(long* values, usz start, usz end, bool reverse) {
    if (start >= end - 1) return start + 1;
    usz run_end = start + 1;
    if (key_less(values[run_end], values[start], reverse)) {
        while (run_end < end && key_less(values[run_end], values[run_end - 1], reverse)) run_end++;
        usz left = start, right = run_end - 1;
        while (left < right) {
            long temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            left++;
            right--;
        }
    } else {
        while (run_end < end && !key_less(values[run_end], values[run_end - 1], reverse)) run_end++;
    }
    return run_end;
}

fn long node_power(usz total_length, usz b1, usz n1, usz b2, usz n2) {
    long a = (long)(2 * b1 + n1);
    long b = (long)(2 * b2 + n2);
    long denominator = (long)(2 * total_length);
    long power = 0L;
    while ((a * (1L << power)) / denominator == (b * (1L << power)) / denominator) power++;
    return power;
}

fn void merge_runs(long* values, usz start1, usz end1, usz end2, bool reverse) {
    long[MAX_VALUES] left = {};
    long[MAX_VALUES] right = {};
    usz left_length = end1 - start1;
    usz right_length = end2 - end1;
    for (usz index = 0; index < left_length; index++) left[index] = values[start1 + index];
    for (usz index = 0; index < right_length; index++) right[index] = values[end1 + index];
    usz i = 0, j = 0, output = start1;
    while (i < left_length && j < right_length) {
        bool take_left = reverse ? left[i] >= right[j] : left[i] <= right[j];
        if (take_left) { values[output] = left[i]; i++; }
        else { values[output] = right[j]; j++; }
        output++;
    }
    while (i < left_length) { values[output] = left[i]; i++; output++; }
    while (j < right_length) { values[output] = right[j]; j++; output++; }
}

fn void power_sort_impl(long* values, usz length, bool reverse) {
    if (length <= 1) return;
    Run[MAX_VALUES] stack = {};
    usz stack_size = 0;
    usz start = 0;
    while (start < length) {
        usz run_end = find_run(values, start, length, reverse);
        usz run_length = run_end - start;
        long power = stack_size == 0 ? 0L : node_power(length, stack[stack_size - 1].start,
            stack[stack_size - 1].length, start, run_length);
        while (stack_size > 0 && stack[stack_size - 1].power >= power) {
            Run previous = stack[stack_size - 1];
            stack_size--;
            merge_runs(values, previous.start, previous.start + previous.length, run_end, reverse);
            start = previous.start;
            run_length = run_end - start;
            power = stack_size == 0 ? 0L : node_power(length, stack[stack_size - 1].start,
                stack[stack_size - 1].length, start, run_length);
        }
        stack[stack_size] = Run{start, run_length, power};
        stack_size++;
        start = run_end;
    }
    while (stack_size > 1) {
        stack_size--;
        Run right = stack[stack_size];
        stack_size--;
        Run left = stack[stack_size];
        usz merged_end = right.start + right.length;
        merge_runs(values, left.start, left.start + left.length, merged_end, reverse);
        usz merged_length = merged_end - left.start;
        long power = stack_size == 0 ? 0L : node_power(length, stack[stack_size - 1].start,
            stack[stack_size - 1].length, left.start, merged_length);
        stack[stack_size] = Run{left.start, merged_length, power};
        stack_size++;
    }
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long power_sort(long* input, usz length, char* output, usz capacity) @export("power_sort") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1L;
    long reverse_value = input[0];
    long count_value = input[1];
    if ((reverse_value != 0L && reverse_value != 1L) || count_value < 0L || count_value > (long)MAX_VALUES) return -1L;
    usz count = (usz)count_value;
    if (length != 2 + count) return -1L;
    long[MAX_VALUES] values = {};
    for (usz index = 0; index < count; index++) {
        long value = input[2 + index];
        if (value < MIN_VALUE || value > MAX_VALUE) return -1L;
        values[index] = value;
    }
    if (count == 0) return 0L;
    usz output_bytes = 8 * count;
    if (output == null || capacity < output_bytes) return -2L;
    power_sort_impl(&values[0], count, reverse_value == 1L);
    for (usz index = 0; index < count; index++) write_i64_le(output, 8 * index, values[index]);
    return (long)output_bytes;
}
