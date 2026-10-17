module clojure_persistent_list_queue;

const usz MAX_OPERATIONS = 256;
const usz MAX_QUEUE_LENGTH = 64;
const usz MAX_VALID_INPUT_LENGTH = 513;
const usz MAX_PARSEABLE_INPUT_LENGTH = 514;
const ulong FNV_OFFSET = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;

fn void hash_byte(ulong* hash, uint value) { *hash = (*hash ^ (ulong)(value & 255)) * FNV_PRIME; }
fn void hash_u16(ulong* hash, uint value) {
    for (uint byte = 0; byte < 2; byte++) hash_byte(hash, value >> (byte * 8));
}
fn void hash_i32(ulong* hash, int value) {
    uint bits = (uint)value;
    for (uint byte = 0; byte < 4; byte++) hash_byte(hash, bits >> (byte * 8));
}
fn void hash_i64(ulong* hash, long value) {
    ulong bits = @bitcast(ulong, value);
    for (uint byte = 0; byte < 8; byte++) hash_byte(hash, (uint)(bits >> (byte * 8)));
}

long clojure_persistent_list_queue(long* input, usz length) @export("clojure_persistent_list_queue") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_OPERATIONS) return -1;
    int operation_count = (int)input[0];
    if (length != 1 + (usz)operation_count * 2 || length > MAX_VALID_INPUT_LENGTH) return -1;

    int[MAX_QUEUE_LENGTH] newest_first;
    int queue_size = 0;
    long[MAX_OPERATIONS] results;
    uchar[MAX_OPERATIONS] opcodes;
    for (int operation = 0; operation < operation_count; operation++) {
        usz offset = 1 + (usz)operation * 2;
        long opcode_value = input[offset], argument = input[offset + 1];
        if (opcode_value < 0 || opcode_value > 3) return -1;
        int opcode = (int)opcode_value;
        opcodes[operation] = (uchar)opcode;
        if (opcode == 0) {
            if (argument < -2147483648L || argument > 2147483647L || queue_size >= (int)MAX_QUEUE_LENGTH) return -1;
            for (int index = queue_size; index > 0; index--) newest_first[index] = newest_first[index - 1];
            newest_first[0] = (int)argument;
            queue_size++;
            results[operation] = queue_size;
        } else if (opcode == 1) {
            if (argument != 0) return -1;
            if (queue_size > 0) queue_size--;
            results[operation] = queue_size;
        } else if (opcode == 2) {
            if (argument != 0) return -1;
            results[operation] = queue_size == 0 ? -9223372036854775807L - 1L : newest_first[queue_size - 1];
        } else {
            if (argument != 0) return -1;
            results[operation] = queue_size == 0 ? 1 : 0;
        }
    }

    ulong hash = FNV_OFFSET;
    hash_u16(&hash, (uint)operation_count);
    for (int operation = 0; operation < operation_count; operation++) {
        hash_byte(&hash, (uint)opcodes[operation]);
        hash_i64(&hash, results[operation]);
    }
    hash_u16(&hash, (uint)queue_size);
    for (int index = queue_size - 1; index >= 0; index--) hash_i32(&hash, newest_first[index]);
    return (long)(hash & 0x7FFFFFFFFFFFFFFFUL);
}
