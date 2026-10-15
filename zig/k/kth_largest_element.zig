/// Descending Lomuto quickselect with the final element as pivot.
const MAX_LENGTH: usize = 512;

export fn kth_largest_element(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_LENGTH + 1) return -1;
    const count = length - 1;
    if (input[0] < 1 or input[0] > count) return -1;
    var values: [MAX_LENGTH]i32 = undefined;
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    const target: usize = @intCast(input[0] - 1);
    var low: usize = 0;
    var high = count - 1;
    while (low <= high) {
        const pivot = values[high];
        var boundary = low;
        for (low..high) |scan| {
            if (values[scan] >= pivot) {
                const temporary = values[boundary];
                values[boundary] = values[scan];
                values[scan] = temporary;
                boundary += 1;
            }
        }
        const temporary = values[boundary];
        values[boundary] = values[high];
        values[high] = temporary;
        if (boundary == target) return values[boundary];
        if (boundary > target) high = boundary - 1
        else low = boundary + 1;
    }
    return -1;
}
