#include <stddef.h>
#include <stdint.h>

#define HUFFBENCH_MIN_PASSES INT64_C(1)
#define HUFFBENCH_MAX_PASSES INT64_C(30)
#define HUFFBENCH_DATA_BYTES 4096
#define HUFFBENCH_OUTPUT_CAPACITY 52

static void heap_adjust(const size_t frequency[512], size_t heap[256], int active, int index) {
    size_t value = heap[index - 1];
    while (index <= active / 2) {
        int child = index * 2;
        if (child < active && frequency[heap[child - 1]] > frequency[heap[child]]) ++child;
        if (frequency[value] < frequency[heap[child - 1]]) break;
        heap[index - 1] = heap[child - 1];
        index = child;
    }
    heap[index - 1] = value;
}

static uint32_t random_state = 1325;

static size_t random4(void) {
    const int64_t ia = 16807;
    const int64_t im = 2147483647;
    const int64_t iq = 127773;
    const int64_t ir = 2836;
    const int64_t mask = 123459876;
    int64_t seed = (int64_t)random_state;
    seed ^= mask;
    const int64_t quotient = seed / iq;
    seed = ia * (seed - quotient * iq) - ir * quotient;
    if (seed < 0) seed += im;
    random_state = (uint32_t)seed;
    const size_t result = (size_t)(seed % 32);
    random_state ^= (uint32_t)mask;
    return result;
}

static int compdecomp(uint8_t data[HUFFBENCH_DATA_BYTES], size_t *compressed_length, uint32_t *checksum) {
    size_t frequency[512] = {0};
    size_t heap[256] = {0};
    int link[512] = {0};
    uint32_t code[256] = {0};
    uint8_t code_length[256] = {0};
    for (size_t index = 0; index < HUFFBENCH_DATA_BYTES; ++index) ++frequency[data[index]];

    int active = 0;
    for (size_t symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] != 0) heap[active++] = symbol;
    }
    for (int index = active; index > 0; --index) heap_adjust(frequency, heap, active, index);
    while (active > 1) {
        --active;
        const size_t first = heap[0];
        heap[0] = heap[active];
        heap_adjust(frequency, heap, active, 1);
        const size_t parent = (size_t)(256 + active);
        frequency[parent] = frequency[heap[0]] + frequency[first];
        link[first] = (int)parent;
        link[heap[0]] = -(int)parent;
        heap[0] = parent;
        heap_adjust(frequency, heap, active, 1);
    }
    link[256 + active] = 0;

    for (size_t symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] == 0) continue;
        size_t depth = 0;
        uint32_t bit = 1;
        uint32_t value = 0;
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
        code_length[symbol] = (uint8_t)depth;
    }

    uint8_t compressed[HUFFBENCH_DATA_BYTES + 1] = {0};
    size_t compressed_used = 0;
    uint8_t bout = 0;
    int bit_index = -1;
    for (size_t index = 0; index < HUFFBENCH_DATA_BYTES; ++index) {
        uint32_t mask = UINT32_C(1) << (code_length[data[index]] - 1);
        for (uint8_t bit = 0; bit < code_length[data[index]]; ++bit) {
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

    int children[512][2];
    int decoded_symbol[512];
    for (size_t node = 0; node < 512; ++node) {
        children[node][0] = -1;
        children[node][1] = -1;
        decoded_symbol[node] = -1;
    }
    int node_count = 1;
    for (size_t symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] == 0) continue;
        int node = 0;
        for (int bit = (int)code_length[symbol] - 1; bit >= 0; --bit) {
            const int direction = (code[symbol] >> bit) & 1u;
            if (children[node][direction] < 0) children[node][direction] = node_count++;
            node = children[node][direction];
        }
        decoded_symbol[node] = (int)symbol;
    }

    size_t decoded = 0;
    uint64_t sum = 0;
    int node = 0;
    for (size_t index = 0; index < compressed_used && decoded < HUFFBENCH_DATA_BYTES; ++index) {
        for (int bit = 7; bit >= 0 && decoded < HUFFBENCH_DATA_BYTES; --bit) {
            const int direction = (compressed[index] >> bit) & 1u;
            node = children[node][direction];
            if (node < 0) return 0;
            if (decoded_symbol[node] >= 0) {
                data[decoded] = (uint8_t)decoded_symbol[node];
                sum += data[decoded];
                ++decoded;
                node = 0;
            }
        }
    }
    if (decoded != HUFFBENCH_DATA_BYTES) return 0;
    *compressed_length = compressed_used;
    *checksum = (uint32_t)sum;
    return 1;
}

static size_t append_decimal(uint8_t *output, size_t used, uint32_t value) {
    uint8_t reversed[10];
    size_t digits = 0;
    do {
        reversed[digits++] = (uint8_t)('0' + value % 10u);
        value /= 10u;
    } while (value != 0);
    while (digits > 0) output[used++] = reversed[--digits];
    return used;
}

static size_t format_output(int64_t passes, size_t compressed_length, uint32_t checksum, uint8_t staged[HUFFBENCH_OUTPUT_CAPACITY]) {
    static const uint8_t prefix[] = "Huffbench passes=";
    static const uint8_t middle[] = " compressed=";
    static const uint8_t suffix[] = " checksum=";
    size_t used = 0;
    for (size_t index = 0; index < sizeof(prefix) - 1; ++index) staged[used++] = prefix[index];
    used = append_decimal(staged, used, (uint32_t)passes);
    for (size_t index = 0; index < sizeof(middle) - 1; ++index) staged[used++] = middle[index];
    used = append_decimal(staged, used, (uint32_t)compressed_length);
    for (size_t index = 0; index < sizeof(suffix) - 1; ++index) staged[used++] = suffix[index];
    used = append_decimal(staged, used, checksum);
    staged[used++] = '\n';
    return used;
}

int64_t coyote_huffbench(int64_t passes, uint8_t *output, size_t output_capacity) {
    if (passes < HUFFBENCH_MIN_PASSES || passes > HUFFBENCH_MAX_PASSES) return -1;
    if (output == NULL) return -2;

    static const uint8_t alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345";
    uint8_t data[HUFFBENCH_DATA_BYTES];
    random_state = 1325;
    for (size_t index = 0; index < HUFFBENCH_DATA_BYTES; ++index) data[index] = alphabet[random4()];

    size_t compressed_length = 0;
    uint32_t checksum = 0;
    for (int64_t pass = 0; pass < passes; ++pass) {
        if (!compdecomp(data, &compressed_length, &checksum)) return -1;
    }

    uint8_t staged[HUFFBENCH_OUTPUT_CAPACITY];
    const size_t used = format_output(passes, compressed_length, checksum, staged);
    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
