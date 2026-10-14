module odd_even_sort;

fn void odd_even_sort(long* values, usz length) @export("odd_even_sort")
{
    if (length < 2) return;
    bool swapped = true;
    while (swapped) {
        swapped = false;
        for (usz index = 0; index + 1 < length; index += 2) {
            if (values[index] > values[index + 1]) {
                long temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        for (usz index = 1; index + 1 < length; index += 2) {
            if (values[index] > values[index + 1]) {
                long temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
    }
}
