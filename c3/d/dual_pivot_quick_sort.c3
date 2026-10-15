module dual_pivot_quick_sort;

fn void dual_pivot_sort_range(long* values, usz low_value, usz high_value)
{
    usz low = low_value;
    usz high = high_value;
    while (high - low > 2) {
        if (values[low] > values[high - 1]) {
            long temporary = values[low];
            values[low] = values[high - 1];
            values[high - 1] = temporary;
        }
        long pivot1 = values[low];
        long pivot2 = values[high - 1];
        usz less = low + 1;
        usz scan = low + 1;
        usz greater = high - 2;
        while (scan <= greater) {
            if (values[scan] < pivot1) {
                long temporary = values[scan];
                values[scan] = values[less];
                values[less] = temporary;
                less++;
            } else if (values[scan] >= pivot2) {
                while (scan < greater && values[greater] > pivot2) greater--;
                long temporary = values[scan];
                values[scan] = values[greater];
                values[greater] = temporary;
                greater--;
                if (values[scan] < pivot1) {
                    long second_temporary = values[scan];
                    values[scan] = values[less];
                    values[less] = second_temporary;
                    less++;
                }
            }
            scan++;
        }
        usz pivot1_index = less - 1;
        usz pivot2_index = greater + 1;
        long first_temporary = values[low];
        values[low] = values[pivot1_index];
        values[pivot1_index] = first_temporary;
        long second_temporary = values[high - 1];
        values[high - 1] = values[pivot2_index];
        values[pivot2_index] = second_temporary;

        usz left_size = pivot1_index - low;
        usz middle_size = pivot2_index - pivot1_index - 1;
        usz right_size = high - pivot2_index - 1;
        if (left_size >= middle_size && left_size >= right_size) {
            dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index);
            dual_pivot_sort_range(values, pivot2_index + 1, high);
            high = pivot1_index;
        } else if (middle_size >= right_size) {
            dual_pivot_sort_range(values, low, pivot1_index);
            dual_pivot_sort_range(values, pivot2_index + 1, high);
            low = pivot1_index + 1;
            high = pivot2_index;
        } else {
            dual_pivot_sort_range(values, low, pivot1_index);
            dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index);
            low = pivot2_index + 1;
        }
    }
    if (high - low == 2 && values[low] > values[low + 1]) {
        long temporary = values[low];
        values[low] = values[low + 1];
        values[low + 1] = temporary;
    }
}

fn void dual_pivot_quick_sort(long* values, usz length) @export("dual_pivot_quick_sort")
{
    if (length > 1) dual_pivot_sort_range(values, 0, length);
}
