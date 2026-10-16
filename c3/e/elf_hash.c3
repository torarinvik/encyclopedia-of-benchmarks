module elf_hash;

const MAX_CODEPOINTS = 8;

fn long elf_hash(long* input, usz length) @export("elf_hash") {
    if (length > MAX_CODEPOINTS || (input == null && length != 0)) return -1;
    ulong hash = 0;
    for (usz index = 0; index < length; index++) {
        long codepoint = input[index];
        if (codepoint < 0 || codepoint > 127) return -1;
        hash = (hash << 4) + (ulong)codepoint;
        ulong high = hash & 0xF0000000;
        if (high != 0) hash ^= high >> 24;
        hash ^= high;
    }
    return (long)hash;
}
