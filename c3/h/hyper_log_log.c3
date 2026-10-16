module hyper_log_log;

extern fn double ceil(double value);

const int MAX_COUNT = 1024;
const int REGISTER_COUNT = 65536;

fn long hyper_log_log(long* input, usz length) @export("hyper_log_log") {
    if (input == null || length < 2 || length > 1025) return -1;
    long count64 = input[0];
    if (count64 < 1 || count64 > MAX_COUNT || length != (usz)(count64 + 1)) return -1;
    usz count = (usz)count64;
    for (usz i = 0; i < count; i++) if (input[1 + i] < 1 || input[1 + i] > 65535) return -1;

    uint8[65536] registers;
    uint8[65536] seen;
    uint16[1024] touched;
    for (int i = 0; i < REGISTER_COUNT; i++) { registers[i] = 0; seen[i] = 0; }
    usz touched_count = 0;
    for (usz i = 0; i < count; i++) {
        uint value = (uint)input[1 + i];
        uint bits = value;
        uint8 rank = 0;
        while ((bits & 1) == 0) { rank++; bits >>= 1; }
        if (seen[value] == 0) { seen[value] = 1; touched[touched_count++] = (uint16)value; }
        if (rank > registers[value]) registers[value] = rank;
    }

    double z = 0.0;
    for (usz i = 0; i < touched_count; i++) z += 1.0 / (double)(1 << registers[touched[i]]);
    double k = (double)touched_count;
    return (long)ceil(0.673 * k * (k / z));
}
