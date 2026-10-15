module three_sum;

const usz MAX_ITEMS = 257;
const usz BYTES_PER_TRIPLET = 12;

fn void sift_down(long* values, usz root_start, usz end) {
    usz root = root_start;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) {
            child++;
        }
        if (values[root] >= values[child]) {
            break;
        }
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

fn void store_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn usz enumerate_triplets(long* values, usz length, char* output, bool write_output) {
    usz result_count = 0;
    for (usz first = 0; first + 2 < length; first++) {
        if (first != 0 && values[first] == values[first - 1]) {
            continue;
        }
        usz left = first + 1;
        usz right = length - 1;
        while (left < right) {
            long sum = values[first] + values[left] + values[right];
            if (sum < 0) {
                left++;
            } else if (sum > 0) {
                right--;
            } else {
                if (write_output) {
                    usz offset = result_count * BYTES_PER_TRIPLET;
                    store_i32_le(output, offset, values[first]);
                    store_i32_le(output, offset + 4, values[left]);
                    store_i32_le(output, offset + 8, values[right]);
                }
                result_count++;
                left++;
                right--;
                while (left < right && values[left] == values[left - 1]) {
                    left++;
                }
                while (left < right && values[right] == values[right + 1]) {
                    right--;
                }
            }
        }
    }
    return result_count;
}

fn long three_sum(long* input, usz length, char* output, usz output_capacity)
    @export("three_sum")
{
    if (length > MAX_ITEMS || (length != 0 && input == null)) {
        return -1;
    }
    long[MAX_ITEMS] values;
    for (usz index = 0; index < length; index++) {
        if (input[index] < -100000 || input[index] > 100000) {
            return -1;
        }
        values[index] = input[index];
    }
    heap_sort(&values[0], length);

    usz maximum_bytes = 0;
    if (length > 1) {
        maximum_bytes = (length * (length - 1) / 2) * BYTES_PER_TRIPLET;
    }
    if (output_capacity < maximum_bytes || output == null) {
        usz needed = enumerate_triplets(&values[0], length, null, false) * BYTES_PER_TRIPLET;
        if (output_capacity < needed || (needed != 0 && output == null)) {
            return -2;
        }
    }
    return (long)enumerate_triplets(&values[0], length, output, output != null);
}
