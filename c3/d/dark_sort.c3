module dark_sort;

fn void dark_sort(long* values, usz length) @export("dark_sort")
{
    if (length < 2) return;
    long maximum = values[0];
    for (usz i = 1; i < length; i++) if (values[i] > maximum) maximum = values[i];
    long[129] counts = {0};
    for (usz i = 0; i < length; i++) counts[(usz)values[i]]++;
    usz output = 0;
    for (long value = 0; value <= maximum; value++) {
        while (counts[(usz)value] > 0) {
            values[output++] = value;
            counts[(usz)value]--;
        }
    }
}
