module quick_select;

const usz MAX_VALUES = 1024;

fn long median_of_three(long first, long middle, long last)
{
    if (first < middle) {
        if (middle < last) return middle;
        return first < last ? last : first;
    }
    if (first < last) return first;
    return middle < last ? last : middle;
}

fn long quick_select(long* values, usz length) @export("quick_select")
{
    if (length == 0 || length > MAX_VALUES) return -1;
    long[MAX_VALUES] scratch;
    for (usz index = 0; index < length; index++) scratch[index] = values[index];

    usz target = length / 2;
    usz low = 0;
    usz high = length;
    while (high - low > 1) {
        usz middle = low + (high - low) / 2;
        long pivot = median_of_three(scratch[low], scratch[middle], scratch[high - 1]);
        usz less = low;
        usz scan = low;
        usz greater = high;
        while (scan < greater) {
            if (scratch[scan] < pivot) {
                long temporary = scratch[less];
                scratch[less] = scratch[scan];
                scratch[scan] = temporary;
                less++;
                scan++;
            } else if (scratch[scan] > pivot) {
                greater--;
                long temporary = scratch[greater];
                scratch[greater] = scratch[scan];
                scratch[scan] = temporary;
            } else {
                scan++;
            }
        }
        if (target < less) {
            high = less;
        } else if (target >= greater) {
            low = greater;
        } else {
            return pivot;
        }
    }
    return scratch[target];
}
