module djb2;

const usz MAX_BYTES = 64;
const usz MAX_PARSED_BYTES = 65;
const ulong UINT32_MODULUS = 4294967296ul;

fn long djb2(long* input, usz length) @export("djb2") {
    if (length > MAX_PARSED_BYTES || (length > 0 && input == null)) return -1;
    if (length > MAX_BYTES) return -1;
    ulong hash = 5381ul;
    for (usz index = 0; index < length; index++) {
        long code_point = input[index];
        if (code_point < 0 || code_point > 255) return -1;
        hash = (hash * 33ul + (ulong)code_point) % UINT32_MODULUS;
    }
    return (long)hash;
}
