module counting_sort;

fn void counting_sort(long* values, long* counts, usz length) @export("counting_sort")
{
    for (usz bucket = 0; bucket < 257; bucket++) counts[bucket] = 0;
    for (usz index = 0; index < length; index++) {
        usz bucket = (usz)(values[index] + 128);
        counts[bucket]++;
    }
    usz output = 0;
    for (usz bucket = 0; bucket < 257; bucket++) {
        while (counts[bucket] > 0) {
            values[output] = (long)bucket - 128;
            output++;
            counts[bucket]--;
        }
    }
}
