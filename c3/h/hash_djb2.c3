module hash_djb2;

const usz MAX_BYTES = 3;

fn long hash_djb2(long* input, usz length) @export("hash_djb2") {
    if (input == null || length < 1 || length > MAX_BYTES + 1) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)MAX_BYTES || length != (usz)count_value + 1) return -1;
    ulong hash = 5381;
    for (usz index = 0; index < (usz)count_value; index++) {
        long byte = input[index + 1];
        if (byte < 1 || byte > 127) return -1;
        hash = hash * 33 + (ulong)byte;
    }
    return (long)hash;
}
