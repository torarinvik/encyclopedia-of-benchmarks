module single_non_duplicate;

const usz MAX_VALUES = 1025;
const long INVALID_RESULT = -2147483649;

// Binary search the pair alignment around the unique value.
fn long single_non_duplicate(long* values, usz length) @export("single_non_duplicate") {
    if (values == null || length == 0 || length > MAX_VALUES || length % 2 == 0) {
        return INVALID_RESULT;
    }
    usz left = 0;
    usz right = length - 1;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (middle % 2 == 0) {
            if (values[middle] == values[middle + 1]) { left = middle + 2; }
            else { right = middle; }
        } else {
            if (values[middle] == values[middle - 1]) { left = middle + 1; }
            else { right = middle - 1; }
        }
    }
    return values[left];
}
