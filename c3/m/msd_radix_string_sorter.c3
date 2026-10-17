module msd_radix_string_sorter;

const usz MAX_STRINGS = 256;
const usz MAX_LENGTH = 32;
const usz MAX_INPUT = 1 + MAX_STRINGS * (1 + MAX_LENGTH) + 1;
const ulong FNV_OFFSET = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;
const ulong MASK_63 = 0x7ffffffffffffffful;

struct EncodedString { u8[32] bytes; usz length; }

fn usz bucket(EncodedString* value, usz digit) {
    if (digit >= value.length) return 0;
    return (usz)value.bytes[digit] + 1;
}

fn void msd_sort(EncodedString* values, EncodedString* auxiliary, usz low, usz high, usz digit) {
    if (high - low < 2 || digit >= MAX_LENGTH) return;
    usz[257] counts = zeroed;
    for (usz i = low; i < high; i += 1) counts[bucket(&values[i], digit)] += 1;
    usz[257] starts;
    usz[257] next;
    usz position = low;
    for (usz b = 0; b < 257; b += 1) { starts[b] = position; next[b] = position; position += counts[b]; }
    for (usz i = low; i < high; i += 1) { usz b = bucket(&values[i], digit); auxiliary[next[b]] = values[i]; next[b] += 1; }
    for (usz i = low; i < high; i += 1) values[i] = auxiliary[i];
    for (usz b = 1; b < 257; b += 1) { usz first = starts[b]; usz last = first + counts[b]; if (last - first > 1) msd_sort(values, auxiliary, first, last, digit + 1); }
}

fn long msd_radix_string_sorter(long* input, usz length) @export("msd_radix_string_sorter") {
    if (input == null || length == 0 || length > MAX_INPUT || input[0] < 0 || input[0] > 256) return -1;
    usz count = (usz)input[0];
    EncodedString[256] values = zeroed;
    EncodedString[256] auxiliary = zeroed;
    usz position = 1;
    for (usz i = 0; i < count; i += 1) {
        if (position >= length || input[position] < 0 || input[position] > 32) return -1;
        usz n = (usz)input[position]; position += 1;
        if (n > length - position) return -1;
        values[i].length = n;
        for (usz digit = 0; digit < n; digit += 1) { if (input[position] < 0 || input[position] > 255) return -1; values[i].bytes[digit] = (u8)input[position]; position += 1; }
    }
    if (position != length) return -1;
    if (count > 1) msd_sort(values, auxiliary, 0, count, 0);
    ulong hash = FNV_OFFSET;
    hash = (hash ^ (ulong)(count & 255)) * FNV_PRIME;
    hash = (hash ^ (ulong)((count >> 8) & 255)) * FNV_PRIME;
    for (usz i = 0; i < count; i += 1) {
        hash = (hash ^ (ulong)values[i].length) * FNV_PRIME;
        for (usz digit = 0; digit < values[i].length; digit += 1) hash = (hash ^ (ulong)values[i].bytes[digit]) * FNV_PRIME;
    }
    return (long)(hash & MASK_63);
}
