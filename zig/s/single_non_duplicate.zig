/// Binary search the pair alignment around the unique value.
const MAX_VALUES: usize = 1025;
const INVALID_RESULT: i64 = -2_147_483_649;

export fn single_non_duplicate(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_VALUES or length % 2 == 0) return INVALID_RESULT;
    var left: usize = 0;
    var right = length / 2;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (values[middle * 2] == values[middle * 2 + 1]) left = middle + 1 else right = middle;
    }
    return values[left * 2];
}
