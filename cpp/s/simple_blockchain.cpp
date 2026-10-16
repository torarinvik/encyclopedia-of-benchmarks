#include <cstddef>
#include <cstdint>
#include <cstring>

#include "sha256.cpp"

namespace {
constexpr std::size_t BC_MAX_VALUES = 465;
constexpr std::size_t BC_MAX_CHAIN = 8;
constexpr std::size_t BC_MAX_DATA = 64;
constexpr std::size_t BC_MAX_HEADER = 160;
constexpr std::int64_t BC_NONCE_ATTEMPTS = 4096;
constexpr std::size_t BC_MAX_OUTPUT = 728;

struct Block {
    std::int64_t timestamp_sec{};
    std::uint8_t data[BC_MAX_DATA]{};
    std::size_t data_length{};
    std::uint8_t previous_hash[64]{};
    std::size_t previous_hash_length{};
    std::int64_t nonce{};
    std::uint8_t hash[64]{};
};

std::size_t append_decimal(std::int64_t *buffer, std::size_t position, std::int64_t value)
{
    std::int64_t digits[20];
    std::size_t count = 0;
    do {
        digits[count++] = '0' + value % 10;
        value /= 10;
    } while (value != 0);
    while (count != 0) buffer[position++] = digits[--count];
    return position;
}

std::size_t make_header(std::size_t index, const Block &block, std::int64_t nonce,
                        std::int64_t *header)
{
    std::size_t length = 0;
    length = append_decimal(header, length, static_cast<std::int64_t>(index));
    length = append_decimal(header, length, block.timestamp_sec);
    header[length++] = '.';
    header[length++] = '0';
    for (std::size_t i = 0; i < block.data_length; ++i)
        header[length++] = block.data[i];
    for (std::size_t i = 0; i < block.previous_hash_length; ++i)
        header[length++] = block.previous_hash[i];
    length = append_decimal(header, length, nonce);
    return length;
}

void to_hex(const std::uint8_t digest[32], std::uint8_t output[64])
{
    static constexpr std::uint8_t hex[] = "0123456789abcdef";
    for (std::size_t i = 0; i < 32; ++i) {
        output[2 * i] = hex[digest[i] >> 4];
        output[2 * i + 1] = hex[digest[i] & 15];
    }
}

bool compute_hash(std::size_t index, const Block &block, std::int64_t nonce,
                  std::uint8_t output[64])
{
    std::int64_t header[BC_MAX_HEADER];
    std::uint8_t digest[32];
    const std::size_t length = make_header(index, block, nonce, header);
    if (sha256(header, length, digest, sizeof(digest)) != 32) return false;
    to_hex(digest, output);
    return true;
}

bool has_prefix(const std::uint8_t hash[64], std::int64_t difficulty)
{
    for (std::int64_t i = 0; i < difficulty; ++i)
        if (hash[i] != '0') return false;
    return true;
}

bool is_valid(const Block *blocks, std::size_t chain_length, std::int64_t difficulty)
{
    for (std::size_t i = 1; i < chain_length; ++i) {
        std::uint8_t recomputed[64];
        if (blocks[i].previous_hash_length != 64 ||
            std::memcmp(blocks[i].previous_hash, blocks[i - 1].hash, 64) != 0)
            return false;
        if (!has_prefix(blocks[i].hash, difficulty)) return false;
        if (!compute_hash(i, blocks[i], blocks[i].nonce, recomputed) ||
            std::memcmp(blocks[i].hash, recomputed, 64) != 0)
            return false;
    }
    return true;
}

std::size_t write_i64(std::uint8_t *output, std::size_t position, std::int64_t value)
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i)
        output[position++] = static_cast<std::uint8_t>(bits >> (8 * i));
    return position;
}
} // namespace

extern "C" std::int64_t simple_blockchain(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 3 || length > BC_MAX_VALUES) return -1;
    const std::int64_t difficulty = input[0];
    const std::int64_t chain_length_value = input[1];
    if (difficulty < 1 || difficulty > 2 || chain_length_value < 1 ||
        chain_length_value > static_cast<std::int64_t>(BC_MAX_CHAIN))
        return -1;

    const std::size_t chain_length = static_cast<std::size_t>(chain_length_value);
    Block blocks[BC_MAX_CHAIN]{};
    constexpr std::int64_t max_timestamp = INT64_C(2147483647);
    if (input[2] < 0 || input[2] > max_timestamp) return -1;
    blocks[0].timestamp_sec = input[2];
    static constexpr std::uint8_t genesis_data[] = "Genesis Block";
    blocks[0].data_length = sizeof(genesis_data) - 1;
    std::memcpy(blocks[0].data, genesis_data, sizeof(genesis_data) - 1);
    blocks[0].previous_hash[0] = '0';
    blocks[0].previous_hash_length = 1;

    std::size_t cursor = 3;
    for (std::size_t i = 1; i < chain_length; ++i) {
        if (cursor + 2 > length) return -1;
        const std::int64_t timestamp_sec = input[cursor++];
        const std::int64_t data_length_value = input[cursor++];
        if (timestamp_sec < 0 || timestamp_sec > max_timestamp ||
            data_length_value < 0 || data_length_value > static_cast<std::int64_t>(BC_MAX_DATA))
            return -1;
        const std::size_t data_length = static_cast<std::size_t>(data_length_value);
        if (cursor + data_length > length) return -1;
        blocks[i].timestamp_sec = timestamp_sec;
        blocks[i].data_length = data_length;
        for (std::size_t j = 0; j < data_length; ++j) {
            if (input[cursor + j] < 0 || input[cursor + j] > 127) return -1;
            blocks[i].data[j] = static_cast<std::uint8_t>(input[cursor + j]);
        }
        cursor += data_length;
    }
    if (cursor != length) return -1;

    for (std::size_t i = 0; i < chain_length; ++i) {
        bool mined = false;
        for (std::int64_t nonce = 0; nonce < BC_NONCE_ATTEMPTS; ++nonce) {
            std::uint8_t candidate[64];
            if (!compute_hash(i, blocks[i], nonce, candidate)) return -1;
            if (has_prefix(candidate, difficulty)) {
                blocks[i].nonce = nonce;
                std::memcpy(blocks[i].hash, candidate, 64);
                mined = true;
                break;
            }
        }
        if (!mined) return -3;
        if (i + 1 < chain_length) {
            std::memcpy(blocks[i + 1].previous_hash, blocks[i].hash, 64);
            blocks[i + 1].previous_hash_length = 64;
        }
    }

    const std::int64_t valid = is_valid(blocks, chain_length, difficulty) ? 1 : 0;
    std::uint8_t payload[BC_MAX_OUTPUT];
    std::size_t written = 0;
    written = write_i64(payload, written, 0);
    written = write_i64(payload, written, chain_length_value);
    for (std::size_t i = 0; i < chain_length; ++i) {
        written = write_i64(payload, written, static_cast<std::int64_t>(i));
        written = write_i64(payload, written, blocks[i].timestamp_sec);
        written = write_i64(payload, written, blocks[i].nonce);
        std::memcpy(payload + written, blocks[i].hash, 64);
        written += 64;
    }
    written = write_i64(payload, written, valid);
    if (output == nullptr || output_capacity < written) return -2;
    std::memcpy(output, payload, written);
    return static_cast<std::int64_t>(written);
}
