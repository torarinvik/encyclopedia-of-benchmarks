module random_pivot_quick_sort;

fn ulong random_pivot_quick_sort_next31(ulong* state)
{
    state[0] = (state[0] * 48271) % 2147483647;
    return state[0];
}

fn ulong random_pivot_quick_sort_next(ulong* state)
{
    ulong high = random_pivot_quick_sort_next31(state);
    ulong low = random_pivot_quick_sort_next31(state);
    return high * 2147483647 + low;
}

fn usz random_pivot_quick_sort_partition(long* values, usz low, usz high, ulong* state)
{
    usz width = high - low;
    usz pivot_index = low + (usz)(random_pivot_quick_sort_next(state) % width);
    long pivot_value = values[pivot_index];
    long pivot_slot = values[high - 1];
    values[high - 1] = pivot_value;
    values[pivot_index] = pivot_slot;

    usz boundary = low;
    for (usz scan = low; scan < high - 1; scan++) {
        if (values[scan] < pivot_value) {
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

fn void random_pivot_quick_sort(long* values, usz length) @export("random_pivot_quick_sort")
{
    if (length < 2) return;
    usz[128] stack_low, stack_high;
    usz stack_size = 0;
    usz low = 0;
    usz high = length;
    ulong random_state = 1;
    while (true) {
        while (high - low > 1) {
            usz pivot = random_pivot_quick_sort_partition(values, low, high, &random_state);
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
