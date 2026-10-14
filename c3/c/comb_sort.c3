module comb_sort;

fn usz shrink_gap(usz gap)
{
    return (gap / 13) * 10 + ((gap % 13) * 10) / 13;
}

fn void comb_sort(long* values, usz length) @export("comb_sort")
{
    if (length < 2) return;
    usz gap = length;
    bool swapped = true;
    while (gap > 1 || swapped) {
        gap = shrink_gap(gap);
        if (gap < 1) gap = 1;
        swapped = false;
        for (usz index = 0; index < length - gap; index++) {
            if (values[index] > values[index + gap]) {
                long temporary = values[index];
                values[index] = values[index + gap];
                values[index + gap] = temporary;
                swapped = true;
            }
        }
    }
}
