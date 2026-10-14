module bead_sort;

fn void bead_sort(long* values, long* scratch, usz length) @export("bead_sort")
{
    if (length < 2) return;
    for (usz level = 0; level < 64; level++) scratch[level] = 0;
    for (usz index = 0; index < length; index++) {
        for (long level = 0; level < values[index]; level++) scratch[(usz)level]++;
    }
    for (usz index = 0; index < length; index++) {
        usz row_from_bottom = length - 1 - index;
        long value = 0;
        for (usz level = 0; level < 64; level++) {
            if (scratch[level] > (long)row_from_bottom) value++;
        }
        values[index] = value;
    }
}
