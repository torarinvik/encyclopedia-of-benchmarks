module rrcache;

const usz MAX_OPERATIONS = 32;
const usz MAX_INPUT_LENGTH = 3 + 3 * MAX_OPERATIONS;
const usz MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS;
const ulong JAVA_MULTIPLIER = 0x5DEECE66Dul;
const ulong JAVA_ADDEND = 0xBul;
const ulong JAVA_MASK = (1ul << 48) - 1ul;

fn uint java_next_bits(ulong* state, usz bits) {
    state[0] = (state[0] * JAVA_MULTIPLIER + JAVA_ADDEND) & JAVA_MASK;
    usz shift = 48 - bits;
    return (uint)(state[0] >> shift);
}

fn uint java_next_int(ulong* state, uint bound) {
    if ((bound & (bound - 1)) == 0)
        return (uint)(((ulong)bound * (ulong)java_next_bits(state, 31)) >> 31);
    while (true) {
        uint bits = java_next_bits(state, 31);
        uint value = bits % bound;
        if ((ulong)bits - (ulong)value + (ulong)(bound - 1) <= 2147483647ul) return value;
    }
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long rrcache(long* input, usz length, char* output, usz capacity)
    @export("rrcache") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 8 || input[2] < 0 || input[2] > (long)MAX_OPERATIONS) return -1;
    usz cache_capacity = (usz)input[0];
    usz operation_count = (usz)input[2];
    if (length != 3 + 3 * operation_count) return -1;

    long[8] keys = {0};
    long[8] values = {0};
    long[32] results = {0};
    usz size = 0;
    ulong random_state = ((ulong)input[1] ^ JAVA_MULTIPLIER) & JAVA_MASK;

    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = 3 + 3 * operation;
        long opcode = input[offset];
        long key = input[offset + 1];
        long value = input[offset + 2];
        if (opcode == 0) {
            if (key < 1 || key > 1024 || value < 100 || value > 1000000) return -1;
            usz index = 0;
            while (index < size && keys[index] != key) index++;
            if (index < size) {
                values[index] = value;
            } else {
                if (size == cache_capacity) {
                    usz evicted = (usz)java_next_int(&random_state, (uint)size);
                    for (usz move = evicted; move + 1 < size; move++) {
                        keys[move] = keys[move + 1];
                        values[move] = values[move + 1];
                    }
                    size--;
                }
                keys[size] = key;
                values[size] = value;
                size++;
            }
            results[operation] = -2;
        } else if (opcode == 1) {
            if (key < 1 || key > 1024 || value != 0) return -1;
            usz index = 0;
            while (index < size && keys[index] != key) index++;
            results[operation] = index < size ? values[index] : -1;
        } else if (opcode == 2) {
            if (key != 0 || value != 0) return -1;
            results[operation] = (long)size;
        } else return -1;
    }

    usz output_bytes = operation_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged;
    for (usz operation = 0; operation < operation_count; operation++)
        put_i64_le(&staged[0], operation * 8, results[operation]);
    for (usz byte = 0; byte < output_bytes; byte++) output[byte] = staged[byte];
    return (long)output_bytes;
}
