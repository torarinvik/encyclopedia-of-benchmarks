#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "sha256.c"

#define BC_MAX_VALUES 465
#define BC_MAX_CHAIN 8
#define BC_MAX_DATA 64
#define BC_MAX_HEADER 160
#define BC_NONCE_ATTEMPTS 4096
#define BC_MAX_OUTPUT 728

typedef struct {
    int64_t timestamp_sec;
    uint8_t data[BC_MAX_DATA];
    size_t data_length;
    uint8_t previous_hash[64];
    size_t previous_hash_length;
    int64_t nonce;
    uint8_t hash[64];
} Block;

static size_t bc_append_decimal(int64_t *buffer, size_t position, int64_t value)
{
    int64_t digits[20];
    size_t count = 0;
    do {
        digits[count++] = '0' + value % 10;
        value /= 10;
    } while (value != 0);
    while (count != 0) buffer[position++] = digits[--count];
    return position;
}

static size_t bc_make_header(size_t index, const Block *block, int64_t nonce,
                             int64_t *header)
{
    size_t length = 0;
    length = bc_append_decimal(header, length, (int64_t)index);
    length = bc_append_decimal(header, length, block->timestamp_sec);
    header[length++] = '.';
    header[length++] = '0';
    for (size_t i = 0; i < block->data_length; ++i)
        header[length++] = block->data[i];
    for (size_t i = 0; i < block->previous_hash_length; ++i)
        header[length++] = block->previous_hash[i];
    length = bc_append_decimal(header, length, nonce);
    return length;
}

static void bc_to_hex(const uint8_t digest[32], uint8_t output[64])
{
    static const uint8_t hex[] = "0123456789abcdef";
    for (size_t i = 0; i < 32; ++i) {
        output[2 * i] = hex[digest[i] >> 4];
        output[2 * i + 1] = hex[digest[i] & 15];
    }
}

static int bc_compute_hash(size_t index, const Block *block, int64_t nonce,
                           uint8_t output[64])
{
    int64_t header[BC_MAX_HEADER];
    uint8_t digest[32];
    size_t length = bc_make_header(index, block, nonce, header);
    if (sha256(header, length, digest, sizeof(digest)) != 32) return 0;
    bc_to_hex(digest, output);
    return 1;
}

static int bc_has_prefix(const uint8_t hash[64], int64_t difficulty)
{
    for (int64_t i = 0; i < difficulty; ++i)
        if (hash[i] != '0') return 0;
    return 1;
}

static int bc_is_valid(const Block *blocks, size_t chain_length, int64_t difficulty)
{
    for (size_t i = 1; i < chain_length; ++i) {
        uint8_t recomputed[64];
        if (blocks[i].previous_hash_length != 64 ||
            memcmp(blocks[i].previous_hash, blocks[i - 1].hash, 64) != 0)
            return 0;
        if (!bc_has_prefix(blocks[i].hash, difficulty)) return 0;
        if (!bc_compute_hash(i, &blocks[i], blocks[i].nonce, recomputed) ||
            memcmp(blocks[i].hash, recomputed, 64) != 0)
            return 0;
    }
    return 1;
}

static size_t bc_write_i64(uint8_t *output, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i)
        output[position++] = (uint8_t)(bits >> (8 * i));
    return position;
}

int64_t simple_blockchain(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > BC_MAX_VALUES) return -1;
    const int64_t difficulty = input[0];
    const int64_t chain_length_value = input[1];
    if (difficulty < 1 || difficulty > 2 || chain_length_value < 1 ||
        chain_length_value > BC_MAX_CHAIN)
        return -1;

    const size_t chain_length = (size_t)chain_length_value;
    Block blocks[BC_MAX_CHAIN] = {0};
    const int64_t max_timestamp = INT64_C(2147483647);
    if (input[2] < 0 || input[2] > max_timestamp) return -1;
    blocks[0].timestamp_sec = input[2];
    static const uint8_t genesis_data[] = "Genesis Block";
    blocks[0].data_length = sizeof(genesis_data) - 1;
    memcpy(blocks[0].data, genesis_data, sizeof(genesis_data) - 1);
    blocks[0].previous_hash[0] = '0';
    blocks[0].previous_hash_length = 1;

    size_t cursor = 3;
    for (size_t i = 1; i < chain_length; ++i) {
        if (cursor + 2 > length) return -1;
        const int64_t timestamp_sec = input[cursor++];
        const int64_t data_length_value = input[cursor++];
        if (timestamp_sec < 0 || timestamp_sec > max_timestamp ||
            data_length_value < 0 || data_length_value > BC_MAX_DATA)
            return -1;
        const size_t data_length = (size_t)data_length_value;
        if (cursor + data_length > length) return -1;
        blocks[i].timestamp_sec = timestamp_sec;
        blocks[i].data_length = data_length;
        for (size_t j = 0; j < data_length; ++j) {
            if (input[cursor + j] < 0 || input[cursor + j] > 127) return -1;
            blocks[i].data[j] = (uint8_t)input[cursor + j];
        }
        cursor += data_length;
    }
    if (cursor != length) return -1;

    for (size_t i = 1; i < chain_length; ++i) {
        memcpy(blocks[i].previous_hash, blocks[i - 1].hash, 64);
        blocks[i].previous_hash_length = 64;
    }
    for (size_t i = 0; i < chain_length; ++i) {
        int mined = 0;
        for (int64_t nonce = 0; nonce < BC_NONCE_ATTEMPTS; ++nonce) {
            uint8_t candidate[64];
            if (!bc_compute_hash(i, &blocks[i], nonce, candidate)) return -1;
            if (bc_has_prefix(candidate, difficulty)) {
                blocks[i].nonce = nonce;
                memcpy(blocks[i].hash, candidate, 64);
                mined = 1;
                break;
            }
        }
        if (!mined) return -3;
        if (i + 1 < chain_length) {
            memcpy(blocks[i + 1].previous_hash, blocks[i].hash, 64);
            blocks[i + 1].previous_hash_length = 64;
        }
    }

    const int64_t valid = bc_is_valid(blocks, chain_length, difficulty);
    uint8_t payload[BC_MAX_OUTPUT];
    size_t written = 0;
    written = bc_write_i64(payload, written, 0);
    written = bc_write_i64(payload, written, chain_length_value);
    for (size_t i = 0; i < chain_length; ++i) {
        written = bc_write_i64(payload, written, (int64_t)i);
        written = bc_write_i64(payload, written, blocks[i].timestamp_sec);
        written = bc_write_i64(payload, written, blocks[i].nonce);
        memcpy(payload + written, blocks[i].hash, 64);
        written += 64;
    }
    written = bc_write_i64(payload, written, valid);
    if (output == NULL || output_capacity < written) return -2;
    memcpy(output, payload, written);
    return (int64_t)written;
}
