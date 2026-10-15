module count_inversions;

const usz MAX_LENGTH = 4096;

// Count strict inversions with bottom-up merge sort.
fn long count_inversions(long* values, usz length) @export("count_inversions")
{
    if (length > MAX_LENGTH || (length > 0 && values == null)) return -1;
    if (length < 2) return 0;

    long[MAX_LENGTH] source;
    long[MAX_LENGTH] scratch;
    for (usz i = 0; i < length; i++) source[i] = values[i];

    long inversions = 0;
    for (usz width = 1; width < length; width *= 2) {
        for (usz low = 0; low < length;) {
            usz middle = low + width;
            if (middle > length) middle = length;
            usz high = middle + width;
            if (high > length) high = length;
            usz left = low, right = middle, output = low;
            while (left < middle && right < high) {
                if (source[left] <= source[right]) {
                    scratch[output++] = source[left++];
                } else {
                    scratch[output++] = source[right++];
                    inversions += (long)(middle - left);
                }
            }
            while (left < middle) scratch[output++] = source[left++];
            while (right < high) scratch[output++] = source[right++];
            low = high;
        }
        for (usz i = 0; i < length; i++) source[i] = scratch[i];
    }
    return inversions;
}
