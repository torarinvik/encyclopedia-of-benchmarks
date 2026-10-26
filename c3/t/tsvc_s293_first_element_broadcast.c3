// Clean-room implementation of TSVC s293; see package rights note.
module tsvc_s293_first_element_broadcast;

const int MAX_N = 32;
const usz MAX_INPUT_LENGTH = 33;

fn void store_i64_le(long value, char* out, usz pos) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { out[pos + b] = (char)(bits & 255); bits >>= 8; }
}

fn long tsvc_s293_first_element_broadcast(long* input, usz length,
        char* output, usz capacity) @export("tsvc_s293_first_element_broadcast") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || length != 1 + input[0].usz()) return -1;
    usz n = input[0].usz();
    for (usz i = 1; i < length; i++) if (input[i] < -8 || input[i] > 8) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long staged[MAX_N];
    for (usz i = 0; i < n; i++) staged[i] = input[1];
    for (usz i = 0; i < n; i++) store_i64_le(staged[i], output, 8 * i);
    return bytes.long();
}
