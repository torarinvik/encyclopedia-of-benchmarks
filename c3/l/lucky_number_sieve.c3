module lucky_number_sieve;

const usz MAX_CANDIDATES = 2048;
const long MAX_BOUND = 4096;

fn long lucky_number_sieve(long* input, usz length, char* output, usz output_capacity)
    @export("lucky_number_sieve") {
    if (input == null || length != 2) return -1;
    long mode = input[0];
    long bound = input[1];
    if ((mode != 0 && mode != 1) || bound < 0 || bound > MAX_BOUND) return -1;

    long[MAX_CANDIDATES] candidates = zeroed;
    usz count = 0;
    long first = mode == 0 ? 1 : 2;
    for (long value = first; value <= bound; value += 2) candidates[count++] = value;

    usz selected = 1;
    while (selected < count) {
        usz step = (usz)candidates[selected];
        if (step > count) break;
        usz write = 0;
        usz rank = 0;
        for (usz read = 0; read < count; read++) {
            rank++;
            if (rank % step != 0) candidates[write++] = candidates[read];
        }
        count = write;
        selected++;
    }

    usz output_bytes = count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < count; index++) {
        ulong bits = (ulong)candidates[index];
        for (usz byte = 0; byte < 8; byte++)
            output[index * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
    return (long)output_bytes;
}
