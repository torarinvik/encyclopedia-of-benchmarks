#include <cstddef>
#include <cstdint>

#define SOURCE_CALLS INT64_C(1)
#define OUTPUT_BYTES 13

extern "C" int64_t shootout_hello(int64_t calls, uint8_t *output, size_t output_capacity) {
    if (calls != SOURCE_CALLS) return -1;
    if (output == nullptr || output_capacity < OUTPUT_BYTES) return -2;
    static constexpr uint8_t source_output[OUTPUT_BYTES] = {
        'h', 'e', 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l', 'd', '\n', '\n'
    };
    uint8_t staged[OUTPUT_BYTES];
    for (size_t index = 0; index < OUTPUT_BYTES; ++index) staged[index] = source_output[index];
    for (size_t index = 0; index < OUTPUT_BYTES; ++index) output[index] = staged[index];
    return OUTPUT_BYTES;
}
