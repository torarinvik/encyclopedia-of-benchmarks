module external_merge_sorter;

const usz MAX_VALUES = 4096;

fn void merge_pass(long* source, long* destination, usz length, usz width) {
    for (usz start = 0; start < length; start += width * 2) {
        usz middle = start + width;
        if (middle > length) middle = length;
        usz end = middle + width;
        if (end > length) end = length;
        usz left = start, right = middle, out = start;
        while (left < middle && right < end) {
            if (source[left] < source[right]) destination[out++] = source[left++];
            else destination[out++] = source[right++];
        }
        while (left < middle) destination[out++] = source[left++];
        while (right < end) destination[out++] = source[right++];
    }
}

fn long external_merge_sorter(long* values, usz length, char* output, usz output_capacity)
        @export("external_merge_sorter") {
    if (length > MAX_VALUES || (length != 0 && values == null)) return -1;
    usz output_bytes = length * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    long[4096] primary = {};
    long[4096] temporary = {};
    for (usz index = 0; index < length; index++) primary[index] = values[index];
    long* source = &primary[0];
    long* destination = &temporary[0];
    for (usz width = 1; width < length;) {
        merge_pass(source, destination, length, width);
        long* swap = source;
        source = destination;
        destination = swap;
        if (width > length / 2) break;
        width *= 2;
    }
    for (usz index = 0; index < length; index++) {
        ulong bits = (ulong)source[index];
        for (usz byte = 0; byte < 8; byte++)
            output[index * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
    return (long)output_bytes;
}
