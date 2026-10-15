/// Binary search the pair alignment around the unique value.
const MAX_VALUES: usize = 1025;
const INVALID_RESULT: i64 = -2_147_483_649;

export fn single_non_duplicate(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_VALUES or length % 2 == 0) return INVALID_RESULT;
    var left: usize = 0;
    var right = length - 1;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (middle % 2 == 0) {
            if (values[middle] == values[middle + 1]) left = middle + 2 else right = middle;
        } else {
            if (values[middle] == values[middle - 1]) left = middle + 1 else right = middle - 1;
        }
    }
    return values[left];
}
