module pancake_sort;

fn void flip_prefix(long* values, usz last)
{
    usz first = 0;
    while (first < last) {
        long temporary = values[first];
        values[first] = values[last];
        values[last] = temporary;
        first++;
        last--;
    }
}

fn void pancake_sort(long* values, usz length) @export("pancake_sort")
{
    for (usz prefix = length; prefix > 1; prefix--) {
        usz maximum = 0;
        for (usz probe = 1; probe < prefix; probe++) {
            if (values[probe] > values[maximum]) maximum = probe;
        }
        if (maximum != prefix - 1) {
            flip_prefix(values, maximum);
            flip_prefix(values, prefix - 1);
        }
    }
}
