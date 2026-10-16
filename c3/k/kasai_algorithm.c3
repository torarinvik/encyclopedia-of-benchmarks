module kasai_algorithm;

const int MAX_LENGTH = 512;
const ulong FNV_OFFSET_BASIS = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong fnv_word(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        hash ^= (bits >> (8 * byte)) & 255;
        hash *= FNV_PRIME;
    }
    return hash;
}

fn long kasai_algorithm(long* values, usz length) @export("kasai_algorithm") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > MAX_LENGTH) return -1;
    usz n = (usz)values[0];
    if (length != 1 + 2 * n) return -1;
    for (usz i = 0; i < n; i++)
        if (values[1 + i] < 0 || values[1 + i] > 127) return -1;

    usz[MAX_LENGTH] suffixes;
    usz[MAX_LENGTH] rank;
    bool[MAX_LENGTH] seen = {false};
    long[MAX_LENGTH] lcp = {0};
    for (usz position = 0; position < n; position++) {
        long suffix_value = values[1 + n + position];
        if (suffix_value < 0 || (ulong)suffix_value >= n) return -1;
        usz suffix = (usz)suffix_value;
        if (seen[suffix]) return -1;
        seen[suffix] = true;
        suffixes[position] = suffix;
        rank[suffix] = position;
    }

    for (usz position = 1; position < n; position++) {
        usz left = suffixes[position - 1], right = suffixes[position];
        long left_tail_rank = left + 1 < n ? (long)rank[left + 1] : -1;
        long right_tail_rank = right + 1 < n ? (long)rank[right + 1] : -1;
        long left_byte = values[1 + left], right_byte = values[1 + right];
        if (left_byte > right_byte || (left_byte == right_byte && left_tail_rank >= right_tail_rank)) return -1;
    }

    usz common = 0;
    for (usz start = 0; start < n; start++) {
        usz current_rank = rank[start];
        if (current_rank == n - 1) { common = 0; continue; }
        usz next_start = suffixes[current_rank + 1];
        while (start + common < n && next_start + common < n &&
               values[1 + start + common] == values[1 + next_start + common]) common++;
        lcp[current_rank] = (long)common;
        if (common > 0) common--;
    }

    ulong hash = fnv_word(FNV_OFFSET_BASIS, (long)n);
    for (usz i = 0; i < n; i++) hash = fnv_word(hash, lcp[i]);
    return (long)(hash & 0x7fffffffffffffff);
}
