module random_scheduling;

const usz MAX_TASK_COUNT = 32;
const usz MAX_INPUT_LENGTH = 35;
const usz MAX_OUTPUT_BYTES = 256;
const ulong JAVA_MULTIPLIER = 0x5DEECE66D;
const ulong JAVA_ADDEND = 0xB;
const ulong JAVA_MASK = 0xFFFFFFFFFFFF;

struct JavaRandom { ulong state; }

uint java_next_bits(JavaRandom* random, uint bits) {
    random.state = (random.state * JAVA_MULTIPLIER + JAVA_ADDEND) & JAVA_MASK;
    return (uint)(random.state >> (48 - bits));
}

uint java_next_int(JavaRandom* random, uint bound) {
    if ((bound & (bound - 1)) == 0) return (uint)(((ulong)bound * java_next_bits(random, 31)) >> 31);
    while (true) {
        uint bits = java_next_bits(random, 31);
        uint value = bits % bound;
        if ((ulong)bits - value + (bound - 1) <= 2147483647) return value;
    }
}

void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long random_scheduling(long* input, usz input_length, char* output, usz capacity)
        @export("random_scheduling") {
    if (input == null || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    long raw_count = input[1];
    if (raw_count < 0 || raw_count > (long)MAX_TASK_COUNT) return -1;
    usz count = (usz)raw_count;
    if (input_length != count + 2) return -1;

    long[MAX_TASK_COUNT] tasks;
    for (usz index = 0; index < count; index += 1) {
        long task = input[index + 2];
        if (task < -2147483648 || task > 2147483647) return -1;
        tasks[index] = task;
    }
    JavaRandom random = { ((ulong)input[0] ^ JAVA_MULTIPLIER) & JAVA_MASK };
    for (usz size = count; size > 1; size -= 1) {
        usz selected = (usz)java_next_int(&random, (uint)size);
        long saved = tasks[size - 1];
        tasks[size - 1] = tasks[selected];
        tasks[selected] = saved;
    }

    usz output_bytes = count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES || output == null || capacity < output_bytes) {
        if (output_bytes > MAX_OUTPUT_BYTES) return -1;
        return -2;
    }
    for (usz index = 0; index < count; index += 1) put_i64_le(output, index * 8, tasks[index]);
    return (long)output_bytes;
}
