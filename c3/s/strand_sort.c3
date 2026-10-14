module strand_sort;

fn void strand_sort(long* values, long* scratch, usz length) @export("strand_sort")
{
    if (length < 2) return;
    usz remaining = length;
    usz result_length = 0;
    while (remaining > 0) {
        usz strand_length = 0;
        usz remaining_write = 0;
        for (usz read = 0; read < remaining; read++) {
            long value = values[read];
            if (strand_length == 0 || value >= scratch[strand_length - 1]) {
                scratch[strand_length] = value;
                strand_length++;
            } else {
                values[remaining_write] = value;
                remaining_write++;
            }
        }
        usz old_start = length - result_length;
        usz new_start = old_start - strand_length;
        for (usz index = 0; index < result_length; index++) values[new_start + index] = values[old_start + index];
        usz left = result_length;
        usz right = strand_length;
        usz destination = length;
        while (left > 0 && right > 0) {
            if (values[new_start + left - 1] > scratch[right - 1]) {
                left--;
                destination--;
                values[destination] = values[new_start + left];
            } else {
                right--;
                destination--;
                values[destination] = scratch[right];
            }
        }
        while (right > 0) {
            right--;
            destination--;
            values[destination] = scratch[right];
        }
        remaining = remaining_write;
        result_length += strand_length;
    }
}
