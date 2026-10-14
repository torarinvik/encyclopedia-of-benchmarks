module selection_sort;

fn void selection_sort(long* values, usz length) @export("selection_sort")
{
    for (usz index = 0; index + 1 < length; index++) {
        usz minimum = index;
        for (usz probe = index + 1; probe < length; probe++) {
            if (values[probe] < values[minimum]) minimum = probe;
        }
        if (minimum != index) {
            long temporary = values[index];
            values[index] = values[minimum];
            values[minimum] = temporary;
        }
    }
}
