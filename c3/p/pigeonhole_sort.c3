module pigeonhole_sort;

fn void pigeonhole_sort(long* values, long* scratch, usz length) @export("pigeonhole_sort")
{
    if (length < 2) return;
    for (usz bucket = 0; bucket < 257; bucket++) scratch[bucket] = 0;
    for (usz index = 0; index < length; index++) {
        usz bucket = (usz)(values[index] + 128);
        scratch[bucket]++;
    }
    usz index = 0;
    for (usz bucket = 0; bucket < 257; bucket++) {
        while (scratch[bucket] > 0) {
            values[index] = (long)bucket - 128;
            index++;
            scratch[bucket]--;
        }
    }
}
