module cocktail_sort;

fn void cocktail_sort(long* values, usz length) @export("cocktail_sort")
{
    usz start = 0;
    usz end = length;
    while (start < end) {
        bool swapped = false;
        for (usz index = start; index + 1 < end; index++) {
            if (values[index] > values[index + 1]) {
                long temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
        end--;
        swapped = false;
        usz index = end;
        while (index > start) {
            if (values[index - 1] > values[index]) {
                long temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = true;
            }
            index--;
        }
        start++;
        if (!swapped) break;
    }
}
