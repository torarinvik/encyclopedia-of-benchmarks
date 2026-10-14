module cycle_sort;

fn void cycle_sort(long* values, usz length) @export("cycle_sort")
{
    if (length < 2) return;
    for (usz cycle_start = 0; cycle_start < length - 1; cycle_start++) {
        long item = values[cycle_start];
        usz position = cycle_start;
        for (usz scan = cycle_start + 1; scan < length; scan++) {
            if (values[scan] < item) position++;
        }
        if (position == cycle_start) continue;
        while (position < length && item == values[position]) position++;
        if (position == length) continue;
        long temporary = values[position];
        values[position] = item;
        item = temporary;
        while (position != cycle_start) {
            position = cycle_start;
            for (usz scan = cycle_start + 1; scan < length; scan++) {
                if (values[scan] < item) position++;
            }
            while (position < length && item == values[position]) position++;
            if (position == length) break;
            temporary = values[position];
            values[position] = item;
            item = temporary;
        }
    }
}
