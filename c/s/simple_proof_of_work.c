#include <stddef.h>
#include <stdint.h>

#include "sha256.c"

#define SPOW_HEADER_VALUES 5
#define SPOW_MAX_FIELD_LENGTH 64
#define SPOW_MAX_INPUT_VALUES (SPOW_HEADER_VALUES + 2 * SPOW_MAX_FIELD_LENGTH)
#define SPOW_MAX_PARSEABLE_VALUES (SPOW_MAX_INPUT_VALUES + 1)
#define SPOW_MAX_OUTPUT_BYTES 72
#define SPOW_MAX_BLOCK_NUMBER INT64_MAX
#define SPOW_MAX_DIFFICULTY 2
#define SPOW_MAX_NONCE 4096

static size_t spow_append_decimal(int64_t *buffer, size_t position, uint64_t value)
{
    int64_t digits[20];
    size_t count = 0;
    do {
        digits[count++] = (int64_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count != 0) buffer[position++] = digits[--count];
    return position;
}

static size_t spow_make_preimage(int64_t block_number,
                                 const int64_t *transactions,
                                 size_t transactions_length,
                                 const int64_t *previous_hash,
                                 size_t previous_hash_length,
                                 uint64_t nonce,
                                 int64_t *preimage)
{
    size_t length = 0;
    length = spow_append_decimal(preimage, length, (uint64_t)block_number);
    for (size_t i = 0; i < transactions_length; ++i)
        preimage[length++] = transactions[i];
    for (size_t i = 0; i < previous_hash_length; ++i)
        preimage[length++] = previous_hash[i];
    return spow_append_decimal(preimage, length, nonce);
}

static int spow_has_zero_prefix(const uint8_t digest[32], int64_t difficulty)
{
    for (int64_t i = 0; i < difficulty; ++i) {
        const uint8_t nibble = (i % 2 == 0)
            ? (uint8_t)(digest[(size_t)i / 2] >> 4)
            : (uint8_t)(digest[(size_t)i / 2] & 0x0f);
        if (nibble != 0) return 0;
    }
    return 1;
}

static void spow_write_i64_le(uint8_t *output, uint64_t value)
{
    for (size_t i = 0; i < 8; ++i)
        output[i] = (uint8_t)(value >> (8 * i));
}

static void spow_write_hex_digest(uint8_t *output, const uint8_t digest[32])
{
    static const uint8_t hex[] = "0123456789abcdef";
    for (size_t i = 0; i < 32; ++i) {
        output[2 * i] = hex[digest[i] >> 4];
        output[2 * i + 1] = hex[digest[i] & 0x0f];
    }
}

int64_t simple_proof_of_work(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < SPOW_HEADER_VALUES ||
        length > SPOW_MAX_PARSEABLE_VALUES)
        return -1;

    const int64_t block_number = input[0];
    const int64_t difficulty = input[1];
    const int64_t max_nonce = input[2];
    const int64_t transactions_length_value = input[3];
    const int64_t previous_hash_length_value = input[4];

    if (block_number < 0 || block_number > SPOW_MAX_BLOCK_NUMBER ||
        difficulty < 0 || difficulty > SPOW_MAX_DIFFICULTY ||
        max_nonce < 0 || max_nonce > SPOW_MAX_NONCE ||
        transactions_length_value < 0 ||
        transactions_length_value > SPOW_MAX_FIELD_LENGTH ||
        previous_hash_length_value < 0 ||
        previous_hash_length_value > SPOW_MAX_FIELD_LENGTH)
        return -1;

    const size_t transactions_length = (size_t)transactions_length_value;
    const size_t previous_hash_length = (size_t)previous_hash_length_value;
    if (length != SPOW_HEADER_VALUES + transactions_length + previous_hash_length)
        return -1;

    const int64_t *transactions = input + SPOW_HEADER_VALUES;
    const int64_t *previous_hash = transactions + transactions_length;
    for (size_t i = 0; i < transactions_length; ++i)
        if (transactions[i] < 0 || transactions[i] > 127) return -1;
    for (size_t i = 0; i < previous_hash_length; ++i)
        if (previous_hash[i] < 0 || previous_hash[i] > 127) return -1;

    if (output == NULL || output_capacity < SPOW_MAX_OUTPUT_BYTES) return -2;

    for (uint64_t nonce = 0; nonce <= (uint64_t)max_nonce; ++nonce) {
        int64_t preimage[19 + 2 * SPOW_MAX_FIELD_LENGTH + 4];
        uint8_t digest[32];
        const size_t preimage_length = spow_make_preimage(
            block_number, transactions, transactions_length,
            previous_hash, previous_hash_length, nonce, preimage);
        if (sha256(preimage, preimage_length, digest, sizeof(digest)) != 32)
            return -1;
        if (spow_has_zero_prefix(digest, difficulty)) {
            spow_write_i64_le(output, nonce);
            spow_write_hex_digest(output + 8, digest);
            return SPOW_MAX_OUTPUT_BYTES;
        }
    }
    return -3;
}
