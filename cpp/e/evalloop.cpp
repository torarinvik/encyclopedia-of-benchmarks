#include <cstddef>
#include <cstdint>

namespace {
constexpr int64_t MIN_PASSES = 0;
constexpr int64_t MAX_PASSES = 1000;
constexpr int BUFFER_SIZE = 2048;
constexpr size_t OUTPUT_CAPACITY = 14;

void execute(uint32_t *sum, int opcode) { *sum += static_cast<uint32_t>(opcode); }

void eval(const int *commands, uint32_t *sum) {
    int pc = 0;
    int opcode = commands[pc++];
    while (opcode != 0) {
        switch (opcode) {
        case 1: case 2: case 3: case 4: case 5: case 6: case 7: case 8:
        case 9: case 10: case 11: case 12: case 13: case 14: case 15: case 16:
        case 17: case 18: case 19: case 20: case 21: case 22: case 23: case 24:
        case 25: case 26: case 27: case 28: case 29: case 30: case 31:
            execute(sum, opcode);
            break;
        default:
            return;
        }
        opcode = commands[pc++];
    }
}

size_t formatOutput(uint32_t sum, uint8_t *staged) {
    constexpr uint8_t prefix[] = {'S', 'u', 'm', ':', ' '};
    for (size_t index = 0; index < sizeof(prefix); ++index) staged[index] = prefix[index];
    size_t used = sizeof(prefix);
    uint8_t reversed[10];
    size_t digits = 0;
    do {
        reversed[digits++] = static_cast<uint8_t>('0' + sum % 10u);
        sum /= 10u;
    } while (sum != 0);
    while (digits > 0) staged[used++] = reversed[--digits];
    staged[used++] = static_cast<uint8_t>('\n');
    return used;
}
} // namespace

extern "C" int64_t evalloop(int64_t passes, uint8_t *output, size_t output_capacity) {
    if (passes < MIN_PASSES || passes > MAX_PASSES) return -1;
    if (output == nullptr) return -2;

    int commands[BUFFER_SIZE];
    for (int index = 0; index < BUFFER_SIZE - 1; ++index) commands[index] = index % 31 + 1;
    commands[BUFFER_SIZE - 1] = 0;
    uint32_t sum = 0;
    for (int64_t pass = 0; pass < passes; ++pass) eval(commands, &sum);

    uint8_t staged[OUTPUT_CAPACITY];
    const size_t used = formatOutput(sum, staged);
    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<int64_t>(used);
}
