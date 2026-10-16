module two_pointers_pair_count;

const usz MAX_VALUES = 256;
const usz MAX_INPUT_LENGTH = MAX_VALUES + 2;

fn void sift_down(long* values, usz root_start, usz end) {
    usz root = root_start;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn void heap_sort(long* values, usz length) {
    for (usz start = length / 2; start > 0; start--) {
        sift_down(values, start - 1, length);
    }
    for (usz end = length; end > 1; end--) {
        long temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

fn long two_pointers_pair_count(long* input, usz length)
    @export("two_pointers_pair_count")
{
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long target = input[0], count_value = input[1];
    if (count_value < 0 || count_value > (long)MAX_VALUES ||
        length != 2 + (usz)count_value ||
        target < -2000000 || target > 2000000) return -1;

    usz count = (usz)count_value;
    long[MAX_VALUES] values;
    for (usz index = 0; index < count; index++) {
        long value = input[2 + index];
        if (value < -1000000 || value > 1000000) return -1;
        values[index] = value;
    }
    heap_sort(&values[0], count);
    if (count < 2) return 0;
    for (usz index = 1; index < count; index++) {
        if (values[index - 1] == values[index]) return -1;
    }

    usz left = 0, right = count - 1;
    long pairs = 0;
    while (left < right) {
        long sum = values[left] + values[right];
        if (sum < target) {
            left++;
        } else if (sum > target) {
            right--;
        } else {
            pairs++;
            left++;
        }
    }
    return pairs;
}

