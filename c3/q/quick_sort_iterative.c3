module quick_sort_iterative;

fn usz quick_sort_iterative_partition(long* values, usz low, usz high)
{
    long pivot = values[high - 1];
    usz boundary = low;
    for (usz scan = low; scan < high - 1; scan++) {
        if (values[scan] <= pivot) {
            long temporary = values[boundary];
            values[boundary] = values[scan];
            values[scan] = temporary;
            boundary++;
        }
    }
    long temporary = values[boundary];
    values[boundary] = values[high - 1];
    values[high - 1] = temporary;
    return boundary;
}

fn void quick_sort_iterative(long* values, usz length) @export("quick_sort_iterative")
{
    if (length < 2) return;

    usz[128] stack_low, stack_high;
    usz stack_size = 0;
    usz low = 0;
    usz high = length;
    while (true) {
        while (high - low > 1) {
            usz pivot = quick_sort_iterative_partition(values, low, high);
            usz left_size = pivot - low;
            usz right_size = high - pivot - 1;
            if (left_size < right_size) {
                if (right_size > 1) {
                    stack_low[stack_size] = pivot + 1;
                    stack_high[stack_size] = high;
                    stack_size++;
                }
                high = pivot;
            } else {
                if (left_size > 1) {
                    stack_low[stack_size] = low;
                    stack_high[stack_size] = pivot;
                    stack_size++;
                }
                low = pivot + 1;
            }
        }
        if (stack_size == 0) break;
        stack_size--;
        low = stack_low[stack_size];
        high = stack_high[stack_size];
    }
}
