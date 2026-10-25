/* Clean-room bounded QR encoder profile; source provenance is in the package README. */
/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <stddef.h>
#include <stdint.h>

enum { QR_SIDE = 25, QR_CELLS = 625, DATA_WORDS = 34, ECC_WORDS = 10,
       MAX_MESSAGE = 21, PREFIX_BYTES = 22 };

static uint8_t gf_multiply(uint8_t left, uint8_t right) {
    unsigned product = 0;
    while (right != 0) {
        if (right & 1u) product ^= left;
        right >>= 1;
        left <<= 1;
        if (left & 0x100u) left ^= 0x11Du;
    }
    return (uint8_t)product;
}

static void put_bits(uint8_t *target, unsigned *position, unsigned value, unsigned width) {
    for (unsigned bit = width; bit > 0; --bit, ++*position)
        if ((value >> (bit - 1)) & 1u)
            target[*position >> 3] |= (uint8_t)(0x80u >> (*position & 7u));
}

static void mark(uint8_t *frame, uint8_t *reserved, int x, int y, int dark) {
    if (x < 0 || x >= QR_SIDE || y < 0 || y >= QR_SIDE) return;
    const unsigned index = (unsigned)y * QR_SIDE + (unsigned)x;
    reserved[index] = 1;
    if (dark) frame[index] = 1;
}

static void finder(uint8_t *frame, uint8_t *reserved, int left, int top) {
    mark(frame, reserved, left + 3, top + 3, 1);
    for (int j = 0; j < 6; ++j) {
        mark(frame, reserved, left + j, top, 1);
        mark(frame, reserved, left, top + j + 1, 1);
        mark(frame, reserved, left + 6, top + j, 1);
        mark(frame, reserved, left + j + 1, top + 6, 1);
    }
    for (int j = 1; j < 5; ++j) {
        mark(frame, reserved, left + j, top + 1, 0);
        mark(frame, reserved, left + 1, top + j + 1, 0);
        mark(frame, reserved, left + 5, top + j, 0);
        mark(frame, reserved, left + j + 1, top + 5, 0);
    }
    for (int j = 2; j < 4; ++j) {
        mark(frame, reserved, left + j, top + 2, 1);
        mark(frame, reserved, left + 2, top + j + 1, 1);
        mark(frame, reserved, left + 4, top + j, 1);
        mark(frame, reserved, left + j + 1, top + 4, 1);
    }
}

static void alignment(uint8_t *frame, uint8_t *reserved, int cx, int cy) {
    mark(frame, reserved, cx, cy, 1);
    for (int j = -2; j < 2; ++j) {
        mark(frame, reserved, cx + j, cy - 2, 1);
        mark(frame, reserved, cx - 2, cy + j + 1, 1);
        mark(frame, reserved, cx + 2, cy + j, 1);
        mark(frame, reserved, cx + j + 1, cy + 2, 1);
    }
    for (int j = 0; j < 2; ++j) {
        mark(frame, reserved, cx - 1, cy + j, 0);
        mark(frame, reserved, cx + 1, cy - j, 0);
        mark(frame, reserved, cx - j, cy - 1, 0);
        mark(frame, reserved, cx + j, cy + 1, 0);
    }
}

static void base_frame(uint8_t *frame, uint8_t *reserved) {
    finder(frame, reserved, 0, 0);
    finder(frame, reserved, QR_SIDE - 7, 0);
    finder(frame, reserved, 0, QR_SIDE - 7);
    alignment(frame, reserved, 18, 18);
    mark(frame, reserved, 8, QR_SIDE - 8, 1);
    for (int x = 0; x < 9; ++x) mark(frame, reserved, x, 8, 0);
    for (int x = 0; x < 8; ++x) {
        mark(frame, reserved, x + QR_SIDE - 8, 8, 0);
        mark(frame, reserved, 8, x, 0);
    }
    for (int y = 0; y < 7; ++y) mark(frame, reserved, 8, y + QR_SIDE - 7, 0);
    for (int p = 0; p < QR_SIDE - 14; ++p) {
        const int dark = (p & 1) == 0;
        mark(frame, reserved, 8 + p, 6, dark);
        mark(frame, reserved, 6, 8 + p, dark);
    }
    for (int y = 0; y < QR_SIDE; ++y)
        for (int x = 0; x <= y; ++x)
            if (frame[y * QR_SIDE + x]) reserved[y * QR_SIDE + x] = 1;
}

static void make_codewords(const uint8_t *message, unsigned length, uint8_t *words) {
    unsigned position = 0;
    put_bits(words, &position, 4, 4);
    put_bits(words, &position, length, 8);
    for (unsigned i = 0; i < length; ++i) put_bits(words, &position, message[i], 8);
    const unsigned remaining = DATA_WORDS * 8u - position;
    put_bits(words, &position, 0, remaining < 4u ? remaining : 4u);
    while (position & 7u) put_bits(words, &position, 0, 1);
    unsigned pad = 0xEC;
    while (position < DATA_WORDS * 8u) {
        put_bits(words, &position, pad, 8);
        pad = pad == 0xEC ? 0x11 : 0xEC;
    }

    uint8_t generator[ECC_WORDS + 1] = {1};
    unsigned degree = 0;
    uint8_t root = 1;
    for (unsigned step = 0; step < ECC_WORDS; ++step) {
        generator[degree + 1] = 1;
        for (unsigned j = degree; j > 0; --j) {
            const uint8_t prior = generator[j - 1];
            const uint8_t current = generator[j];
            generator[j] = current ? (uint8_t)(prior ^ gf_multiply(current, root)) : prior;
        }
        generator[0] = gf_multiply(generator[0], root);
        ++degree;
        root = gf_multiply(root, 2);
    }
    uint8_t ecc[ECC_WORDS] = {0};
    for (unsigned i = 0; i < DATA_WORDS; ++i) {
        const uint8_t factor = words[i] ^ ecc[0];
        for (unsigned j = 0; j + 1 < ECC_WORDS; ++j)
            ecc[j] = (uint8_t)(ecc[j + 1] ^ gf_multiply(factor, generator[j + 1]));
        ecc[ECC_WORDS - 1] = gf_multiply(factor, generator[0]);
    }
    for (unsigned i = 0; i < ECC_WORDS; ++i) words[DATA_WORDS + i] = ecc[i];
}

static void place_data(uint8_t *frame, const uint8_t *reserved, const uint8_t *words) {
    int x = QR_SIDE - 1, y = QR_SIDE - 1;
    int moving_up = 1, moving_left = 1;
    for (unsigned i = 0; i < DATA_WORDS + ECC_WORDS; ++i) {
        uint8_t byte = words[i];
        for (unsigned bit = 0; bit < 8; ++bit, byte <<= 1) {
            if (byte & 0x80u) frame[y * QR_SIDE + x] = 1;
            do {
                if (moving_left) --x;
                else {
                    ++x;
                    if (moving_up) {
                        if (y != 0) --y;
                        else {
                            x -= 2;
                            moving_up = 0;
                            if (x == 6) { --x; y = 9; }
                        }
                    } else if (y != QR_SIDE - 1) ++y;
                    else {
                        x -= 2;
                        moving_up = 1;
                        if (x == 6) { --x; y -= 8; }
                    }
                }
                moving_left = !moving_left;
            } while (reserved[y * QR_SIDE + x]);
        }
    }
}

static int masked_by(unsigned mask, unsigned x, unsigned y) {
    const unsigned product = x * y;
    switch (mask) {
    case 0: return ((x + y) & 1u) == 0;
    case 1: return (y & 1u) == 0;
    case 2: return x % 3u == 0;
    case 3: return (x + y) % 3u == 0;
    case 4: return ((y / 2u + x / 3u) & 1u) == 0;
    case 5: return product % 2u + product % 3u == 0;
    case 6: return ((product % 2u + product % 3u) & 1u) == 0;
    default: return (((x + y) % 2u + product % 3u) & 1u) == 0;
    }
}

static void add_format(uint8_t *candidate, unsigned mask) {
    const unsigned data = 8u | mask;
    unsigned remainder = data << 10;
    for (int bit = 14; bit >= 10; --bit)
        if (remainder & (1u << bit)) remainder ^= 0x537u << (bit - 10);
    const unsigned word = ((data << 10) | remainder) ^ 0x5412u;
    for (unsigned bit = 0; bit < 6; ++bit)
        candidate[bit * QR_SIDE + 8] = (word >> bit) & 1u;
    candidate[7 * QR_SIDE + 8] = (word >> 6) & 1u;
    candidate[8 * QR_SIDE + 8] = (word >> 7) & 1u;
    candidate[8 * QR_SIDE + 7] = (word >> 8) & 1u;
    for (unsigned bit = 9; bit < 15; ++bit)
        candidate[8 * QR_SIDE + 14 - bit] = (word >> bit) & 1u;
    for (unsigned bit = 0; bit < 8; ++bit)
        candidate[8 * QR_SIDE + QR_SIDE - 1 - bit] = (word >> bit) & 1u;
    for (unsigned bit = 8; bit < 15; ++bit)
        candidate[(QR_SIDE - 15 + bit) * QR_SIDE + 8] = (word >> bit) & 1u;
    candidate[(QR_SIDE - 8) * QR_SIDE + 8] = 1;
}

static unsigned penalty(const uint8_t *matrix) {
    unsigned score = 0, dark = 0;
    for (unsigned i = 0; i < QR_CELLS; ++i) dark += matrix[i] != 0;
    for (unsigned axis = 0; axis < 2; ++axis) {
        for (unsigned line = 0; line < QR_SIDE; ++line) {
            unsigned run = 1;
            for (unsigned step = 1; step < QR_SIDE; ++step) {
                const unsigned a = axis ? matrix[step * QR_SIDE + line] : matrix[line * QR_SIDE + step];
                const unsigned b = axis ? matrix[(step - 1) * QR_SIDE + line] : matrix[line * QR_SIDE + step - 1];
                if (a == b) ++run;
                else { if (run >= 5) score += run - 2; run = 1; }
            }
            if (run >= 5) score += run - 2;
            for (unsigned start = 0; start + 11 <= QR_SIDE; ++start) {
                unsigned pattern = 0;
                for (unsigned j = 0; j < 11; ++j) {
                    const unsigned value = axis ? matrix[(start + j) * QR_SIDE + line]
                                                 : matrix[line * QR_SIDE + start + j];
                    pattern = (pattern << 1) | value;
                }
                if (pattern == 0x05D || pattern == 0x5D0) score += 40;
            }
        }
    }
    for (unsigned y = 0; y + 1 < QR_SIDE; ++y)
        for (unsigned x = 0; x + 1 < QR_SIDE; ++x) {
            const uint8_t value = matrix[y * QR_SIDE + x];
            if (value == matrix[y * QR_SIDE + x + 1] &&
                value == matrix[(y + 1) * QR_SIDE + x] &&
                value == matrix[(y + 1) * QR_SIDE + x + 1]) score += 3;
        }
    const unsigned balance = (unsigned)(dark * 20u > QR_CELLS * 10u
        ? dark * 20u - QR_CELLS * 10u : QR_CELLS * 10u - dark * 20u);
    score += (balance / QR_CELLS) * 10u;
    return score;
}

static unsigned evaluate_masks(const uint8_t *frame, const uint8_t *reserved) {
    unsigned best_score = UINT32_MAX, best_mask = 0;
    for (unsigned mask = 0; mask < 8; ++mask) {
        uint8_t candidate[QR_CELLS];
        for (unsigned i = 0; i < QR_CELLS; ++i) {
            candidate[i] = frame[i];
            if (!reserved[i] && masked_by(mask, i % QR_SIDE, i / QR_SIDE))
                candidate[i] ^= 1u;
        }
        add_format(candidate, mask);
        const unsigned score = penalty(candidate);
        if (score < best_score) { best_score = score; best_mask = mask; }
    }
    return best_mask;
}

int64_t qrduino(const int64_t *input, size_t length,
                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_MESSAGE + 2) return -1;
    if (input[0] < 1 || input[0] > MAX_MESSAGE || length != (size_t)input[0] + 1) return -1;
    const unsigned message_length = (unsigned)input[0];
    uint8_t message[MAX_MESSAGE];
    for (unsigned i = 0; i < message_length; ++i) {
        if (input[i + 1] < 1 || input[i + 1] > 127) return -1;
        message[i] = (uint8_t)input[i + 1];
    }
    if (output == NULL || capacity < PREFIX_BYTES) return -2;

    uint8_t words[DATA_WORDS + ECC_WORDS] = {0};
    uint8_t frame[QR_CELLS] = {0}, reserved[QR_CELLS] = {0};
    uint8_t staged[PREFIX_BYTES] = {0};
    make_codewords(message, message_length, words);
    base_frame(frame, reserved);
    place_data(frame, reserved, words);
    for (unsigned y = 0; y < 6; ++y)
        for (unsigned x = 0; x < QR_SIDE; ++x)
            if (frame[y * QR_SIDE + x] && y * 4 + x / 8 < PREFIX_BYTES)
                staged[y * 4 + x / 8] |= (uint8_t)(0x80u >> (x & 7u));
    (void)evaluate_masks(frame, reserved);
    for (unsigned i = 0; i < PREFIX_BYTES; ++i) output[i] = staged[i];
    return PREFIX_BYTES;
}
