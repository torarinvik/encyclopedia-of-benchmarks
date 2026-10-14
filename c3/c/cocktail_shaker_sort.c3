module cocktail_shaker_sort;

fn void cocktail_shaker_sort(long* values, usz length) @export("cocktail_shaker_sort")
{
    if (length < 2) return;
    while (true) {
        bool swapped = false;
        for (usz index = 0; index + 1 < length; index++) {
            if (values[index] > values[index + 1]) {
                long temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
        swapped = false;
        usz index = length - 1;
        while (index > 0) {
            if (values[index - 1] > values[index]) {
                long temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = true;
            }
            index--;
        }
        if (!swapped) break;
    }
}
