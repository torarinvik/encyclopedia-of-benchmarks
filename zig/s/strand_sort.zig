/// Stable strand sort using caller-provided temporary storage.
export fn strand_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2) return;
    var remaining = length;
    var result_length: usize = 0;
    while (remaining > 0) {
        var strand_length: usize = 0;
        var remaining_write: usize = 0;
        for (0..remaining) |read| {
            const value = values[read];
            if (strand_length == 0 or value >= scratch[strand_length - 1]) {
                scratch[strand_length] = value;
                strand_length += 1;
            } else {
                values[remaining_write] = value;
                remaining_write += 1;
            }
        }
        const old_start = length - result_length;
        const new_start = old_start - strand_length;
        for (0..result_length) |index| values[new_start + index] = values[old_start + index];
        var left = result_length;
        var right = strand_length;
        var destination = length;
        while (left > 0 and right > 0) {
            if (values[new_start + left - 1] > scratch[right - 1]) {
                left -= 1;
                destination -= 1;
                values[destination] = values[new_start + left];
            } else {
                right -= 1;
                destination -= 1;
                values[destination] = scratch[right];
            }
        }
        while (right > 0) {
            right -= 1;
            destination -= 1;
            values[destination] = scratch[right];
        }
        remaining = remaining_write;
        result_length += strand_length;
    }
}
