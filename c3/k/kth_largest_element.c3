module kth_largest_element;

const MAX_LENGTH = 512;

// Descending Lomuto quickselect with the final element as pivot.
fn long kth_largest_element(long* input, usz length) @export("kth_largest_element") {
    if (input == null || length < 2 || length > MAX_LENGTH + 1) { return -1; }
    usz count = length - 1;
    if (input[0] < 1 || input[0] > (long)count) { return -1; }
    int[512] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) { return -1; }
        values[index] = (int)value;
    }
    usz target = (usz)input[0] - 1;
    usz low = 0;
    usz high = count - 1;
    while (low <= high) {
        int pivot = values[high];
        usz boundary = low;
        for (usz scan = low; scan < high; scan++) {
            if (values[scan] >= pivot) {
                int temporary = values[boundary];
                values[boundary] = values[scan];
                values[scan] = temporary;
                boundary++;
            }
        }
        int temporary = values[boundary];
        values[boundary] = values[high];
        values[high] = temporary;
        if (boundary == target) { return values[boundary]; }
        if (boundary > target) { high = boundary - 1; }
        else { low = boundary + 1; }
    }
    return -1;
}
