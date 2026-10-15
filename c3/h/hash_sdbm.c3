module hash_sdbm;

const usz MAX_BYTES = 64;
const ulong HIGH_BIT = 9223372036854775808ul;

fn long hash_sdbm(long* input, usz length) @export("hash_sdbm") {
    if (length == 0 || length > MAX_BYTES || input == null) return -1;
    ulong hash = 0;
    for (usz index = 0; index < length; index++) {
        long byte = input[index];
        if (byte < 1 || byte > 127) return -1;
        ulong value = (ulong)byte;
        hash = value + (hash << 6) + (hash << 16) - hash;
    }
    if (hash < HIGH_BIT) return (long)hash;
    return -9223372036854775807 - 1 + (long)(hash - HIGH_BIT);
}
