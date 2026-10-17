#include <cstddef>
#include <cstdint>

namespace {
constexpr std::uint32_t delta = UINT32_C(0x9e3779b9);
constexpr std::uint32_t decrypt_sum = UINT32_C(0xc6ef3720);

std::uint64_t combine_words(std::uint32_t low, std::uint32_t high) {
    return (static_cast<std::uint64_t>(high) << 32) | low;
}

std::uint64_t tea_encrypt(std::uint64_t block, std::uint64_t key0, std::uint64_t key1) {
    auto b0 = static_cast<std::uint32_t>(block);
    auto b1 = static_cast<std::uint32_t>(block >> 32);
    const auto k0 = static_cast<std::uint32_t>(key0);
    const auto k1 = static_cast<std::uint32_t>(key0 >> 32);
    const auto k2 = static_cast<std::uint32_t>(key1);
    const auto k3 = static_cast<std::uint32_t>(key1 >> 32);
    std::uint32_t sum = 0;
    for (std::size_t round = 0; round < 32; ++round) {
        sum += delta;
        b0 += ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1);
        b1 += ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3);
    }
    return (static_cast<std::uint64_t>(b1) << 32) | b0;
}

std::uint64_t tea_decrypt(std::uint64_t block, std::uint64_t key0, std::uint64_t key1) {
    auto b0 = static_cast<std::uint32_t>(block);
    auto b1 = static_cast<std::uint32_t>(block >> 32);
    const auto k0 = static_cast<std::uint32_t>(key0);
    const auto k1 = static_cast<std::uint32_t>(key0 >> 32);
    const auto k2 = static_cast<std::uint32_t>(key1);
    const auto k3 = static_cast<std::uint32_t>(key1 >> 32);
    std::uint32_t sum = decrypt_sum;
    for (std::size_t round = 0; round < 32; ++round) {
        b1 -= ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3);
        b0 -= ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1);
        sum -= delta;
    }
    return (static_cast<std::uint64_t>(b1) << 32) | b0;
}

void store_u64_le(std::uint8_t *output, std::size_t offset, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
}
} // namespace

// Return ciphertext and the decrypted round-trip block as little-endian u64s.
extern "C" std::int64_t tea(const std::int64_t *input, std::size_t length,
                            std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length != 6) return -1;
    for (std::size_t index = 0; index < 6; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
    if (output == nullptr || output_capacity < 16) return -2;

    const auto block = combine_words(static_cast<std::uint32_t>(static_cast<std::int32_t>(input[0])),
                                     static_cast<std::uint32_t>(static_cast<std::int32_t>(input[1])));
    const auto key0 = combine_words(static_cast<std::uint32_t>(static_cast<std::int32_t>(input[2])),
                                    static_cast<std::uint32_t>(static_cast<std::int32_t>(input[3])));
    const auto key1 = combine_words(static_cast<std::uint32_t>(static_cast<std::int32_t>(input[4])),
                                    static_cast<std::uint32_t>(static_cast<std::int32_t>(input[5])));
    const auto ciphertext = tea_encrypt(block, key0, key1);
    const auto recovered = tea_decrypt(ciphertext, key0, key1);
    store_u64_le(output, 0, ciphertext);
    store_u64_le(output, 8, recovered);
    return 16;
}
