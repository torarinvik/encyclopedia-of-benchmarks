/* Clean-room bounded pcompress2 pipeline: cyclic BWT, RLE, adaptive arithmetic. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 32
#define MAX_OUTPUT_BYTES (8 + MAX_LENGTH * 16)
#define SYMBOLS 257
#define MAX_FREQUENCY 16383

typedef struct {
    uint8_t *bytes;
    size_t length;
    uint8_t buffer;
    int bits_to_go;
} bit_writer;

static int rotation_less(const uint8_t *input, size_t n, size_t left, size_t right) {
    for (size_t offset = 0; offset < n; ++offset) {
        uint8_t a = input[(left + offset) % n];
        uint8_t b = input[(right + offset) % n];
        if (a != b) return a < b;
    }
    return left < right;
}

static void output_bit(bit_writer *writer, int bit) {
    writer->buffer >>= 1;
    if (bit) writer->buffer |= 0x80u;
    writer->bits_to_go -= 1;
    if (writer->bits_to_go == 0) {
        writer->bytes[writer->length++] = writer->buffer;
        writer->bits_to_go = 8;
    }
}

static void bit_plus_follow(bit_writer *writer, int bit, int *follow) {
    output_bit(writer, bit);
    while (*follow > 0) {
        output_bit(writer, !bit);
        *follow -= 1;
    }
}

static void encode_symbol(int symbol, int *cum, uint32_t *low, uint32_t *high,
                          int *follow, bit_writer *writer) {
    const uint64_t range = (uint64_t)(*high - *low) + 1u;
    *high = *low + (uint32_t)(range * (uint32_t)cum[symbol - 1] / (uint32_t)cum[0]) - 1u;
    *low += (uint32_t)(range * (uint32_t)cum[symbol] / (uint32_t)cum[0]);
    for (;;) {
        if (*high < 32768u) {
            bit_plus_follow(writer, 0, follow);
        } else if (*low >= 32768u) {
            bit_plus_follow(writer, 1, follow);
            *low -= 32768u;
            *high -= 32768u;
        } else if (*low >= 16384u && *high < 49152u) {
            *follow += 1;
            *low -= 16384u;
            *high -= 16384u;
        } else {
            break;
        }
        *low *= 2u;
        *high = *high * 2u + 1u;
    }
}

static void update_model(int symbol, int *char_to_index, uint8_t *index_to_char,
                         int *freq, int *cum) {
    if (cum[0] == MAX_FREQUENCY) {
        int total = 0;
        for (int i = SYMBOLS; i >= 0; --i) {
            freq[i] = (freq[i] + 1) / 2;
            cum[i] = total;
            total += freq[i];
        }
    }
    int i = symbol;
    while (freq[i] == freq[i - 1]) --i;
    if (i < symbol) {
        const uint8_t old_i = index_to_char[i];
        const uint8_t old_symbol = index_to_char[symbol];
        index_to_char[i] = old_symbol;
        index_to_char[symbol] = old_i;
        char_to_index[old_i] = symbol;
        char_to_index[old_symbol] = i;
    }
    freq[i] += 1;
    while (i > 0) cum[--i] += 1;
}

static size_t arithmetic_encode(const uint8_t *data, size_t data_length, uint8_t *encoded) {
    int char_to_index[256];
    uint8_t index_to_char[SYMBOLS + 1] = {0};
    int freq[SYMBOLS + 1];
    int cum[SYMBOLS + 1];
    for (int i = 0; i < 256; ++i) {
        char_to_index[i] = i + 1;
        index_to_char[i + 1] = (uint8_t)i;
    }
    for (int i = 0; i <= SYMBOLS; ++i) {
        freq[i] = 1;
        cum[i] = SYMBOLS - i;
    }
    freq[0] = 0;

    bit_writer writer = {encoded, 0, 0, 8};
    uint32_t low = 0;
    uint32_t high = 65535u;
    int follow = 0;
    for (size_t i = 0; i < data_length; ++i) {
        const int symbol = char_to_index[data[i]];
        encode_symbol(symbol, cum, &low, &high, &follow, &writer);
        update_model(symbol, char_to_index, index_to_char, freq, cum);
    }
    encode_symbol(257, cum, &low, &high, &follow, &writer);
    follow += 1;
    bit_plus_follow(&writer, low < 16384u ? 0 : 1, &follow);
    /* Match the source bit writer's unconditional final-byte flush. */
    writer.bytes[writer.length++] = (uint8_t)(writer.buffer >> writer.bits_to_go);
    return writer.length;
}

static size_t compress_bounded(const uint8_t *input, size_t n, uint8_t *output) {
    size_t order[MAX_LENGTH];
    uint8_t last[MAX_LENGTH];
    uint8_t rle[MAX_LENGTH * 2];
    size_t rle_length = 0;
    for (size_t i = 0; i < n; ++i) order[i] = i;
    for (size_t i = 1; i < n; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && rotation_less(input, n, key, order[j - 1])) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }
    size_t primary = 0;
    for (size_t row = 0; row < n; ++row) {
        if (order[row] == 0) primary = row;
        last[row] = input[(order[row] + n - 1) % n];
    }

    for (size_t i = 0; i < n;) {
        size_t count = 1;
        const uint8_t value = last[i];
        while (i + count < n && last[i + count] == value && count < 127) ++count;
        if (count == 1) {
            while (i + count < n && last[i + count - 1] != last[i + count] &&
                   (i + count + 1 == n || last[i + count] != last[i + count + 1])) {
                ++count;
            }
            rle[rle_length++] = (uint8_t)(count & 0x7f);
            for (size_t j = 0; j < count; ++j) rle[rle_length++] = last[i + j];
            i += count;
        } else {
            rle[rle_length++] = (uint8_t)(count | 0x80);
            rle[rle_length++] = value;
            i += count;
        }
    }

    output[0] = (uint8_t)n;
    output[1] = output[2] = output[3] = 0;
    output[4] = (uint8_t)primary;
    output[5] = output[6] = output[7] = 0;
    return 8 + arithmetic_encode(rle, rle_length, output + 8);
}

int64_t pcompress2(const int64_t *values, size_t length,
                   uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || values[0] < 1 || values[0] > MAX_LENGTH) return -1;
    const size_t n = (size_t)values[0];
    if (length != n + 1) return -1;
    uint8_t input[MAX_LENGTH];
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = values[i + 1];
        if (value < 0 || value > 255) return -1;
        input[i] = (uint8_t)value;
    }
    uint8_t encoded[MAX_OUTPUT_BYTES];
    const size_t encoded_length = compress_bounded(input, n, encoded);
    if (output == NULL || output_capacity < encoded_length) return -2;
    for (size_t i = 0; i < encoded_length; ++i) output[i] = encoded[i];
    return (int64_t)encoded_length;
}
