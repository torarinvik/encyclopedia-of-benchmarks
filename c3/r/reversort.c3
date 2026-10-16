module reversort;

fn void reversort(long* values, usz length) @export("reversort") {
    for (usz index = 0; index + 1 < length; index++) {
        usz minimum = index;
        for (usz probe = index + 1; probe < length; probe++) {
            if (values[probe] < values[minimum]) minimum = probe;
        }
        usz left = index;
        usz right = minimum;
        while (left < right) {
            long temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            left++;
            right--;
        }
    }
}
