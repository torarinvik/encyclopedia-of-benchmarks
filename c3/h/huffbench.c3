module huffbench;

const long HUFFBENCH_MIN_PASSES = 1;
const long HUFFBENCH_MAX_PASSES = 30;
const usz HUFFBENCH_DATA_BYTES = 4096;
const usz HUFFBENCH_OUTPUT_CAPACITY = 52;

fn void heap_adjust(usz* frequency, usz* heap, int active, int index) {
    usz value = heap[index - 1];
    while (index <= active / 2) {
        int child = index * 2;
        if (child < active && frequency[heap[child - 1]] > frequency[heap[child]]) ++child;
        if (frequency[value] < frequency[heap[child - 1]]) break;
        heap[index - 1] = heap[child - 1];
        index = child;
    }
    heap[index - 1] = value;
}

uint random_state = 1325;

fn usz random4() {
    long ia = 16807;
    long im = 2147483647;
    long iq = 127773;
    long ir = 2836;
    long mask = 123459876;
    long seed = (long)random_state;
    seed ^= mask;
    long quotient = seed / iq;
    seed = ia * (seed - quotient * iq) - ir * quotient;
    if (seed < 0) seed += im;
    random_state = (uint)seed;
    usz result = (usz)(seed % 32);
    random_state ^= (uint)mask;
    return result;
}

fn int compdecomp(char* data, usz *compressed_length, uint *checksum) {
    usz[512] frequency = {};
    usz[256] heap = {};
    int[512] link = {};
    uint[256] code = {};
    char[256] code_length = {};
    for (usz index = 0; index < HUFFBENCH_DATA_BYTES; ++index) ++frequency[data[index]];

    int active = 0;
    for (usz symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] != 0) heap[active++] = symbol;
    }
    for (int index = active; index > 0; --index) heap_adjust(&frequency[0], &heap[0], active, index);
    while (active > 1) {
        --active;
        usz first = heap[0];
        heap[0] = heap[active];
        heap_adjust(&frequency[0], &heap[0], active, 1);
        usz parent = (usz)(256 + active);
        frequency[parent] = frequency[heap[0]] + frequency[first];
        link[first] = (int)parent;
        link[heap[0]] = -(int)parent;
        heap[0] = parent;
        heap_adjust(&frequency[0], &heap[0], active, 1);
    }
    link[256 + active] = 0;

    for (usz symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] == 0) continue;
        usz depth = 0;
        uint bit = 1;
        uint value = 0;
        int parent = link[symbol];
        while (parent != 0) {
            if (parent < 0) {
                value += bit;
                parent = -parent;
            }
            parent = link[parent];
            bit <<= 1;
            ++depth;
        }
        code[symbol] = value;
        code_length[symbol] = (char)depth;
    }

    char[HUFFBENCH_DATA_BYTES + 1] compressed = {};
    usz compressed_used = 0;
    char bout = 0;
    int bit_index = -1;
    for (usz index = 0; index < HUFFBENCH_DATA_BYTES; ++index) {
        uint mask = 1u << (code_length[data[index]] - 1);
        for (char bit = 0; bit < code_length[data[index]]; ++bit) {
            if (bit_index == 7) {
                compressed[compressed_used++] = bout;
                bit_index = 0;
                bout = 0;
            } else {
                ++bit_index;
                bout <<= 1;
            }
            if (code[data[index]] & mask) bout |= 1;
            mask >>= 1;
        }
    }
    bout <<= (7 - bit_index);
    compressed[compressed_used++] = bout;

    int[2][512] children;
    int[512] decoded_symbol;
    for (usz node = 0; node < 512; ++node) {
        children[node][0] = -1;
        children[node][1] = -1;
        decoded_symbol[node] = -1;
    }
    int node_count = 1;
    for (usz symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] == 0) continue;
        int node = 0;
        for (int bit = (int)code_length[symbol] - 1; bit >= 0; --bit) {
            int direction = (int)((code[symbol] >> bit) & 1u);
            if (children[node][direction] < 0) children[node][direction] = node_count++;
            node = children[node][direction];
        }
        decoded_symbol[node] = (int)symbol;
    }

    usz decoded = 0;
    ulong sum = 0;
    int node = 0;
    for (usz index = 0; index < compressed_used && decoded < HUFFBENCH_DATA_BYTES; ++index) {
        for (int bit = 7; bit >= 0 && decoded < HUFFBENCH_DATA_BYTES; --bit) {
            int direction = (int)((compressed[index] >> bit) & 1u);
            node = children[node][direction];
            if (node < 0) return 0;
            if (decoded_symbol[node] >= 0) {
                data[decoded] = (char)decoded_symbol[node];
                sum += data[decoded];
                ++decoded;
                node = 0;
            }
        }
    }
    if (decoded != HUFFBENCH_DATA_BYTES) return 0;
    *compressed_length = compressed_used;
    *checksum = (uint)sum;
    return 1;
}

fn usz append_decimal(char *output, usz used, uint value) {
    char[10] reversed;
    usz digits = 0;
    do {
        reversed[digits++] = (char)('0' + value % 10u);
        value /= 10u;
    } while (value != 0);
    while (digits > 0) output[used++] = reversed[--digits];
    return used;
}

fn usz format_output(long passes, usz compressed_length, uint checksum, char* staged) {
    const char* PREFIX = "Huffbench passes=";
    const char* MIDDLE = " compressed=";
    const char* SUFFIX = " checksum=";
    usz used = 0;
    for (usz index = 0; index < 17; ++index) staged[used++] = PREFIX[index];
    used = append_decimal(staged, used, (uint)passes);
    for (usz index = 0; index < 12; ++index) staged[used++] = MIDDLE[index];
    used = append_decimal(staged, used, (uint)compressed_length);
    for (usz index = 0; index < 10; ++index) staged[used++] = SUFFIX[index];
    used = append_decimal(staged, used, checksum);
    staged[used++] = '\n';
    return used;
}

fn long coyote_huffbench(long passes, char *output, usz output_capacity) @export("coyote_huffbench") {
    if (passes < HUFFBENCH_MIN_PASSES || passes > HUFFBENCH_MAX_PASSES) return -1;
    if (output == null) return -2;

    const char* ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345";
    char[HUFFBENCH_DATA_BYTES] data;
    random_state = 1325;
    for (usz index = 0; index < HUFFBENCH_DATA_BYTES; ++index) data[index] = ALPHABET[random4()];

    usz compressed_length = 0;
    uint checksum = 0;
    for (long pass = 0; pass < passes; ++pass) {
        if (!compdecomp(&data[0], &compressed_length, &checksum)) return -1;
    }

    char[HUFFBENCH_OUTPUT_CAPACITY] staged;
    usz used = format_output(passes, compressed_length, checksum, &staged[0]);
    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; ++index) output[index] = staged[index];
    return (long)used;
}
