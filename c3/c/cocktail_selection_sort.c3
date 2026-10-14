module cocktail_selection_sort;

const MAX_VALUES = 1024;

fn void cocktail_selection_sort(long* values, usz length) @export("cocktail_selection_sort") {
    if (length > MAX_VALUES) return;
    usz low = 0;
    usz high = length;
    while (low < high && high - low > 1) {
        usz minimum_index = low;
        usz maximum_index = low;
        for (usz index = low + 1; index < high; index++) {
            if (values[index] < values[minimum_index]) minimum_index = index;
            if (values[index] > values[maximum_index]) maximum_index = index;
        }
        long minimum = values[minimum_index];
        values[minimum_index] = values[low];
        values[low] = minimum;
        if (maximum_index == low) maximum_index = minimum_index;
        long maximum = values[maximum_index];
        values[maximum_index] = values[high - 1];
        values[high - 1] = maximum;
        low++;
        high--;
    }
}
