#include <cstddef>
#include <cstdint>

namespace {
constexpr int64_t MIN_PASSES = 1;
constexpr int64_t MAX_PASSES = 30;
constexpr std::size_t DATA_BYTES = 4096;
constexpr std::size_t OUTPUT_CAPACITY = 52;

void heap_adjust(const std::size_t frequency[512], std::size_t heap[256], int active, int index) {
    const std::size_t value = heap[index - 1];
    while (index <= active / 2) {
        int child = index * 2;
        if (child < active && frequency[heap[child - 1]] > frequency[heap[child]]) ++child;
        if (frequency[value] < frequency[heap[child - 1]]) break;
        heap[index - 1] = heap[child - 1];
        index = child;
    }
    heap[index - 1] = value;
}

std::size_t random4(int64_t *seed) {
    *seed ^= INT64_C(123459876);
    const int64_t quotient = *seed / INT64_C(127773);
    *seed = INT64_C(16807) * (*seed - quotient * INT64_C(127773)) - INT64_C(2836) * quotient;
    if (*seed < 0) *seed += INT64_C(2147483647);
    const std::size_t result = static_cast<std::size_t>(*seed % 32);
    *seed ^= INT64_C(123459876);
    return result;
}

bool compdecomp(uint8_t data[DATA_BYTES], std::size_t *compressed_length, uint32_t *checksum) {
    std::size_t frequency[512]{};
    std::size_t heap[256]{};
    int link[512]{};
    uint32_t code[256]{};
    uint8_t code_length[256]{};
    for (std::size_t index = 0; index < DATA_BYTES; ++index) ++frequency[data[index]];
    int active = 0;
    for (std::size_t symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] != 0) heap[active++] = symbol;
    }
    for (int index = active; index > 0; --index) heap_adjust(frequency, heap, active, index);
    while (active > 1) {
        --active;
        const std::size_t first = heap[0];
        heap[0] = heap[active];
        heap_adjust(frequency, heap, active, 1);
        const std::size_t parent = static_cast<std::size_t>(256 + active);
        frequency[parent] = frequency[heap[0]] + frequency[first];
        link[first] = static_cast<int>(parent);
        link[heap[0]] = -static_cast<int>(parent);
        heap[0] = parent;
        heap_adjust(frequency, heap, active, 1);
    }
    link[256 + active] = 0;

    for (std::size_t symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] == 0) continue;
        std::size_t depth = 0;
        uint32_t bit = 1;
        uint32_t value = 0;
        int parent = link[symbol];
        while (parent != 0) {
            if (parent < 0) { value += bit; parent = -parent; }
            parent = link[parent];
            bit <<= 1;
            ++depth;
        }
        code[symbol] = value;
        code_length[symbol] = static_cast<uint8_t>(depth);
    }

    uint8_t compressed[DATA_BYTES + 1]{};
    std::size_t compressed_used = 0;
    uint8_t bout = 0;
    int bit_index = -1;
    for (std::size_t index = 0; index < DATA_BYTES; ++index) {
        uint32_t mask = UINT32_C(1) << (code_length[data[index]] - 1);
        for (uint8_t bit = 0; bit < code_length[data[index]]; ++bit) {
            if (bit_index == 7) {
                compressed[compressed_used++] = bout;
                bit_index = 0;
                bout = 0;
            } else { ++bit_index; bout <<= 1; }
            if (code[data[index]] & mask) bout |= 1;
            mask >>= 1;
        }
    }
    bout <<= (7 - bit_index);
    compressed[compressed_used++] = bout;

    int children[512][2];
    int decoded_symbol[512];
    for (std::size_t node = 0; node < 512; ++node) {
        children[node][0] = -1;
        children[node][1] = -1;
        decoded_symbol[node] = -1;
    }
    int node_count = 1;
    for (std::size_t symbol = 0; symbol < 256; ++symbol) {
        if (frequency[symbol] == 0) continue;
        int node = 0;
        for (int bit = static_cast<int>(code_length[symbol]) - 1; bit >= 0; --bit) {
            const int direction = static_cast<int>((code[symbol] >> bit) & 1u);
            if (children[node][direction] < 0) children[node][direction] = node_count++;
            node = children[node][direction];
        }
        decoded_symbol[node] = static_cast<int>(symbol);
    }

    std::size_t decoded = 0;
    uint64_t sum = 0;
    int node = 0;
    for (std::size_t index = 0; index < compressed_used && decoded < DATA_BYTES; ++index) {
        for (int bit = 7; bit >= 0 && decoded < DATA_BYTES; --bit) {
            const int direction = (compressed[index] >> bit) & 1u;
            node = children[node][direction];
            if (node < 0) return false;
            if (decoded_symbol[node] >= 0) {
                data[decoded] = static_cast<uint8_t>(decoded_symbol[node]);
                sum += data[decoded++];
                node = 0;
            }
        }
    }
    if (decoded != DATA_BYTES) return false;
    *compressed_length = compressed_used;
    *checksum = static_cast<uint32_t>(sum);
    return true;
}

std::size_t append_decimal(uint8_t *output, std::size_t used, uint32_t value) {
    uint8_t reversed[10];
    std::size_t digits = 0;
    do { reversed[digits++] = static_cast<uint8_t>('0' + value % 10u); value /= 10u; } while (value != 0);
    while (digits > 0) output[used++] = reversed[--digits];
    return used;
}

std::size_t format_output(int64_t passes, std::size_t compressed_length, uint32_t checksum, uint8_t staged[OUTPUT_CAPACITY]) {
    constexpr char prefix[] = "Huffbench passes=";
    constexpr char middle[] = " compressed=";
    constexpr char suffix[] = " checksum=";
    std::size_t used = 0;
    for (std::size_t index = 0; index < sizeof(prefix) - 1; ++index) staged[used++] = static_cast<uint8_t>(prefix[index]);
    used = append_decimal(staged, used, static_cast<uint32_t>(passes));
    for (std::size_t index = 0; index < sizeof(middle) - 1; ++index) staged[used++] = static_cast<uint8_t>(middle[index]);
    used = append_decimal(staged, used, static_cast<uint32_t>(compressed_length));
    for (std::size_t index = 0; index < sizeof(suffix) - 1; ++index) staged[used++] = static_cast<uint8_t>(suffix[index]);
    used = append_decimal(staged, used, checksum);
    staged[used++] = '\n';
    return used;
}
} // namespace

extern "C" int64_t coyote_huffbench(int64_t passes, uint8_t *output, std::size_t output_capacity) {
    if (passes < MIN_PASSES || passes > MAX_PASSES) return -1;
    if (output == nullptr) return -2;
    constexpr char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345";
    uint8_t data[DATA_BYTES];
    int64_t seed = 1325;
    for (std::size_t index = 0; index < DATA_BYTES; ++index) data[index] = static_cast<uint8_t>(alphabet[random4(&seed)]);
    std::size_t compressed_length = 0;
    uint32_t checksum = 0;
    for (int64_t pass = 0; pass < passes; ++pass) {
        if (!compdecomp(data, &compressed_length, &checksum)) return -1;
    }
    uint8_t staged[OUTPUT_CAPACITY];
    const std::size_t used = format_output(passes, compressed_length, checksum, staged);
    if (output_capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<int64_t>(used);
}
