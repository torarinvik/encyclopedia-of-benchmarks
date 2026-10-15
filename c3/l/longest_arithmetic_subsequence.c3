module longest_arithmetic_subsequence;

fn long longest_arithmetic_subsequence(long* values, usz length) @export("longest_arithmetic_subsequence") {
    if (length > 64 || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++)
        if (values[i] < -1000000 || values[i] > 1000000) return -1;
    if (length <= 1) return (long)length;

    long[64][127] keys;
    long[64][127] sizes;
    long maximum = 2;
    for (usz right = 0; right < length; right++) {
        for (usz slot = 0; slot < 127; slot++) sizes[right][slot] = 0;
        for (usz left = 0; left < right; left++) {
            long difference = values[right] - values[left];
            usz slot = (usz)((difference % 127 + 127) % 127);
            while (sizes[left][slot] != 0 && keys[left][slot] != difference) slot = (slot + 1) % 127;
            long candidate = (sizes[left][slot] == 0 ? 1 : sizes[left][slot]) + 1;
            slot = (usz)((difference % 127 + 127) % 127);
            while (sizes[right][slot] != 0 && keys[right][slot] != difference) slot = (slot + 1) % 127;
            if (sizes[right][slot] == 0 || candidate > sizes[right][slot]) {
                keys[right][slot] = difference;
                sizes[right][slot] = candidate;
            }
            if (candidate > maximum) maximum = candidate;
        }
    }
    return maximum;
}
