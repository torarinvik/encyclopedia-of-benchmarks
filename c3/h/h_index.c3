module h_index;

// Find the greatest h for which at least h citations are >= h.
fn long h_index(long* citations, usz length) @export("h_index") {
    if (length > 5000) return -1;
    for (usz index = 0; index < length; index++) {
        if (citations[index] < 0 || citations[index] > 1000) return -1;
    }

    usz low = 0;
    usz high = length < 1000 ? length : 1000;
    while (low < high) {
        usz middle = low + (high - low + 1) / 2;
        usz qualifying = 0;
        for (usz index = 0; index < length; index++) {
            if ((ulong)citations[index] >= middle) {
                qualifying++;
                if (qualifying >= middle) break;
            }
        }
        if (qualifying >= middle) { low = middle; }
        else { high = middle - 1; }
    }
    return (long)low;
}
