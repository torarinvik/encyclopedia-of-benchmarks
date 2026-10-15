#include <cstddef>
#include <cstdint>

static void put_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<uint8_t>(value >> (8 * byte));
}

extern "C" int64_t linear_congruential_generator(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == nullptr || length != 5) return -1;
    const int64_t seed = input[0], multiplier = input[1], increment = input[2], modulo = input[3], count = input[4];
    if (modulo < 2 || modulo > INT64_C(4294967296) || seed < 0 || seed >= modulo || multiplier < 0 || multiplier > 65535 || increment < 0 || increment > INT64_C(4294967295) || count < 0 || count > 512) return -1;
    const size_t n = static_cast<size_t>(count), required = 8 * n;
    if (capacity < required || (required != 0 && output == nullptr)) return -2;
    uint64_t state = static_cast<uint64_t>(seed);
    for (size_t i = 0; i < n; ++i) {
        state = (static_cast<uint64_t>(multiplier) * state + static_cast<uint64_t>(increment)) % static_cast<uint64_t>(modulo);
        put_u64_le(output, i * 8, state);
    }
    return static_cast<int64_t>(required);
}
