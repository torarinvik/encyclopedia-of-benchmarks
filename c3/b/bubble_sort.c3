module bubble_sort;

fn void bubble_sort(long* values, usz length) @export("bubble_sort")
{
    for (usz end = length; end > 1; end--) {
        bool swapped = false;
        for (usz index = 0; index + 1 < end; index++) {
            if (values[index] > values[index + 1]) {
                long temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
    }
}
