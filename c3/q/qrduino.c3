// Clean-room bounded QR encoder; package README documents source provenance.
// SPDX-License-Identifier: GPL-3.0-or-later
module qrduino;

const int QR_SIDE = 25;
const int QR_CELLS = 625;
const int DATA_WORDS = 34;
const int ECC_WORDS = 10;
const int MAX_MESSAGE = 21;
const int PREFIX_BYTES = 22;

fn uchar gf_multiply(uchar left, uchar right) {
    uint product = 0;
    while (right != 0) {
        if (right & 1) product ^= left;
        right >>= 1;
        left <<= 1;
        if (left & 0x100) left ^= 0x11d;
    }
    return (uchar)product;
}

fn void put_bits(uchar* target, usz* position, uint value, usz width) {
    for (usz bit = width; bit > 0; bit--) {
        if ((value >> (bit - 1)) & 1)
            target[*position >> 3] |= (uchar)(0x80 >> (*position & 7));
        *position += 1;
    }
}

fn void mark(uchar* frame, uchar* reserved, int x, int y, bool dark) {
    if (x < 0 || x >= QR_SIDE || y < 0 || y >= QR_SIDE) return;
    usz index = (usz)(y * QR_SIDE + x);
    reserved[index] = 1;
    if (dark) frame[index] = 1;
}

fn void finder(uchar* frame, uchar* reserved, int left, int top) {
    mark(frame, reserved, left + 3, top + 3, true);
    for (int j = 0; j < 6; j++) {
        mark(frame, reserved, left + j, top, true);
        mark(frame, reserved, left, top + j + 1, true);
        mark(frame, reserved, left + 6, top + j, true);
        mark(frame, reserved, left + j + 1, top + 6, true);
    }
    for (int j = 1; j < 5; j++) {
        mark(frame, reserved, left + j, top + 1, false);
        mark(frame, reserved, left + 1, top + j + 1, false);
        mark(frame, reserved, left + 5, top + j, false);
        mark(frame, reserved, left + j + 1, top + 5, false);
    }
    for (int j = 2; j < 4; j++) {
        mark(frame, reserved, left + j, top + 2, true);
        mark(frame, reserved, left + 2, top + j + 1, true);
        mark(frame, reserved, left + 4, top + j, true);
        mark(frame, reserved, left + j + 1, top + 4, true);
    }
}

fn void alignment(uchar* frame, uchar* reserved, int cx, int cy) {
    mark(frame, reserved, cx, cy, true);
    for (int j = -2; j < 2; j++) {
        mark(frame, reserved, cx + j, cy - 2, true);
        mark(frame, reserved, cx - 2, cy + j + 1, true);
        mark(frame, reserved, cx + 2, cy + j, true);
        mark(frame, reserved, cx + j + 1, cy + 2, true);
    }
    for (int j = 0; j < 2; j++) {
        mark(frame, reserved, cx - 1, cy + j, false);
        mark(frame, reserved, cx + 1, cy - j, false);
        mark(frame, reserved, cx - j, cy - 1, false);
        mark(frame, reserved, cx + j, cy + 1, false);
    }
}

fn void base_frame(uchar* frame, uchar* reserved) {
    finder(frame, reserved, 0, 0);
    finder(frame, reserved, QR_SIDE - 7, 0);
    finder(frame, reserved, 0, QR_SIDE - 7);
    alignment(frame, reserved, 18, 18);
    mark(frame, reserved, 8, QR_SIDE - 8, true);
    for (int x = 0; x < 9; x++) mark(frame, reserved, x, 8, false);
    for (int x = 0; x < 8; x++) {
        mark(frame, reserved, x + QR_SIDE - 8, 8, false);
        mark(frame, reserved, 8, x, false);
    }
    for (int y = 0; y < 7; y++) mark(frame, reserved, 8, y + QR_SIDE - 7, false);
    for (int p = 0; p < QR_SIDE - 14; p++) {
        bool dark = (p & 1) == 0;
        mark(frame, reserved, 8 + p, 6, dark);
        mark(frame, reserved, 6, 8 + p, dark);
    }
    for (int y = 0; y < QR_SIDE; y++)
        for (int x = 0; x <= y; x++)
            if (frame[y * QR_SIDE + x]) reserved[y * QR_SIDE + x] = 1;
}

fn void make_codewords(uchar* message, usz length, uchar* words) {
    usz position = 0;
    put_bits(words, &position, 4, 4);
    put_bits(words, &position, (uint)length, 8);
    for (usz i = 0; i < length; i++) put_bits(words, &position, message[i], 8);
    usz remaining = DATA_WORDS * 8 - position;
    put_bits(words, &position, 0, remaining < 4 ? remaining : 4);
    while (position & 7) put_bits(words, &position, 0, 1);
    uint pad = 0xec;
    while (position < DATA_WORDS * 8) {
        put_bits(words, &position, pad, 8);
        pad = pad == 0xec ? 0x11 : 0xec;
    }

    uchar[ECC_WORDS + 1] generator = {};
    generator[0] = 1;
    usz degree = 0;
    uchar root = 1;
    for (usz step = 0; step < ECC_WORDS; step++) {
        generator[degree + 1] = 1;
        for (usz j = degree; j > 0; j--) {
            uchar prior = generator[j - 1];
            uchar current = generator[j];
            generator[j] = current != 0 ? prior ^ gf_multiply(current, root) : prior;
        }
        generator[0] = gf_multiply(generator[0], root);
        degree++;
        root = gf_multiply(root, 2);
    }
    uchar[ECC_WORDS] ecc = {};
    for (usz i = 0; i < DATA_WORDS; i++) {
        uchar factor = words[i] ^ ecc[0];
        for (usz j = 0; j + 1 < ECC_WORDS; j++)
            ecc[j] = ecc[j + 1] ^ gf_multiply(factor, generator[j + 1]);
        ecc[ECC_WORDS - 1] = gf_multiply(factor, generator[0]);
    }
    for (usz i = 0; i < ECC_WORDS; i++) words[DATA_WORDS + i] = ecc[i];
}

fn void place_data(uchar* frame, uchar* reserved, uchar* words) {
    int x = QR_SIDE - 1, y = QR_SIDE - 1;
    bool moving_up = true, moving_left = true;
    for (usz i = 0; i < DATA_WORDS + ECC_WORDS; i++) {
        uchar byte = words[i];
        for (usz bit = 0; bit < 8; bit++) {
            if (byte & 0x80) frame[y * QR_SIDE + x] = 1;
            byte <<= 1;
            do {
                if (moving_left) x--;
                else {
                    x++;
                    if (moving_up) {
                        if (y != 0) y--;
                        else {
                            x -= 2;
                            moving_up = false;
                            if (x == 6) { x--; y = 9; }
                        }
                    } else if (y != QR_SIDE - 1) y++;
                    else {
                        x -= 2;
                        moving_up = true;
                        if (x == 6) { x--; y -= 8; }
                    }
                }
                moving_left = !moving_left;
            } while (reserved[y * QR_SIDE + x]);
        }
    }
}

fn bool masked_by(usz mask, usz x, usz y) {
    usz product = x * y;
    switch (mask) {
    case 0: return ((x + y) & 1) == 0;
    case 1: return (y & 1) == 0;
    case 2: return x % 3 == 0;
    case 3: return (x + y) % 3 == 0;
    case 4: return ((y / 2 + x / 3) & 1) == 0;
    case 5: return product % 2 + product % 3 == 0;
    case 6: return ((product % 2 + product % 3) & 1) == 0;
    default: return (((x + y) % 2 + product % 3) & 1) == 0;
    }
}

fn void add_format(uchar* candidate, usz mask) {
    uint data = 8 | (uint)mask;
    uint remainder = data << 10;
    for (int bit = 14; bit >= 10; bit--)
        if (remainder & (1 << bit)) remainder ^= 0x537 << (bit - 10);
    uint word = ((data << 10) | remainder) ^ 0x5412;
    for (usz bit = 0; bit < 6; bit++) candidate[bit * QR_SIDE + 8] = (word >> bit) & 1;
    candidate[7 * QR_SIDE + 8] = (word >> 6) & 1;
    candidate[8 * QR_SIDE + 8] = (word >> 7) & 1;
    candidate[8 * QR_SIDE + 7] = (word >> 8) & 1;
    for (usz bit = 9; bit < 15; bit++) candidate[8 * QR_SIDE + 14 - bit] = (word >> bit) & 1;
    for (usz bit = 0; bit < 8; bit++) candidate[8 * QR_SIDE + QR_SIDE - 1 - bit] = (word >> bit) & 1;
    for (usz bit = 8; bit < 15; bit++) candidate[(QR_SIDE - 15 + bit) * QR_SIDE + 8] = (word >> bit) & 1;
    candidate[(QR_SIDE - 8) * QR_SIDE + 8] = 1;
}

fn uint penalty(uchar* matrix) {
    uint score = 0, dark = 0;
    for (usz i = 0; i < QR_CELLS; i++) dark += matrix[i] != 0;
    for (usz axis = 0; axis < 2; axis++) {
        for (usz line = 0; line < QR_SIDE; line++) {
            usz run = 1;
            for (usz step = 1; step < QR_SIDE; step++) {
                usz a = axis != 0 ? step * QR_SIDE + line : line * QR_SIDE + step;
                usz b = axis != 0 ? (step - 1) * QR_SIDE + line : line * QR_SIDE + step - 1;
                if (matrix[a] == matrix[b]) run++;
                else { if (run >= 5) score += (uint)(run - 2); run = 1; }
            }
            if (run >= 5) score += (uint)(run - 2);
            for (usz start = 0; start + 11 <= QR_SIDE; start++) {
                uint pattern = 0;
                for (usz j = 0; j < 11; j++) {
                    usz index = axis != 0 ? (start + j) * QR_SIDE + line : line * QR_SIDE + start + j;
                    pattern = (pattern << 1) | matrix[index];
                }
                if (pattern == 0x05d || pattern == 0x5d0) score += 40;
            }
        }
    }
    for (usz y = 0; y + 1 < QR_SIDE; y++)
        for (usz x = 0; x + 1 < QR_SIDE; x++) {
            uchar value = matrix[y * QR_SIDE + x];
            if (value == matrix[y * QR_SIDE + x + 1] &&
                value == matrix[(y + 1) * QR_SIDE + x] &&
                value == matrix[(y + 1) * QR_SIDE + x + 1]) score += 3;
        }
    uint balance = dark * 20 > QR_CELLS * 10 ? dark * 20 - QR_CELLS * 10 : QR_CELLS * 10 - dark * 20;
    return score + (balance / QR_CELLS) * 10;
}

fn usz evaluate_masks(uchar* frame, uchar* reserved) {
    uint best_score = 0xffffffff, best_mask = 0;
    for (usz mask = 0; mask < 8; mask++) {
        uchar[QR_CELLS] candidate = {};
        for (usz i = 0; i < QR_CELLS; i++) {
            candidate[i] = frame[i];
            if (!reserved[i] && masked_by(mask, i % QR_SIDE, i / QR_SIDE)) candidate[i] ^= 1;
        }
        add_format(&candidate[0], mask);
        uint score = penalty(&candidate[0]);
        if (score < best_score) { best_score = score; best_mask = (uint)mask; }
    }
    return (usz)best_mask;
}

fn long qrduino(long* input, usz length, uchar* output, usz capacity) @export("qrduino") {
    if (input == null || length < 2 || length > MAX_MESSAGE + 2) return -1;
    if (input[0] < 1 || input[0] > MAX_MESSAGE || length != (usz)input[0] + 1) return -1;
    usz message_length = (usz)input[0];
    uchar[MAX_MESSAGE] message = {};
    for (usz i = 0; i < message_length; i++) {
        if (input[i + 1] < 1 || input[i + 1] > 127) return -1;
        message[i] = (uchar)input[i + 1];
    }
    if (output == null || capacity < PREFIX_BYTES) return -2;
    uchar[DATA_WORDS + ECC_WORDS] words = {};
    uchar[QR_CELLS] frame = {};
    uchar[QR_CELLS] reserved = {};
    uchar[PREFIX_BYTES] staged = {};
    make_codewords(&message[0], message_length, &words[0]);
    base_frame(&frame[0], &reserved[0]);
    place_data(&frame[0], &reserved[0], &words[0]);
    for (usz y = 0; y < 6; y++)
        for (usz x = 0; x < QR_SIDE; x++)
            if (frame[y * QR_SIDE + x] && y * 4 + x / 8 < PREFIX_BYTES)
                staged[y * 4 + x / 8] |= (uchar)(0x80 >> (x & 7));
    evaluate_masks(&frame[0], &reserved[0]);
    for (usz i = 0; i < PREFIX_BYTES; i++) output[i] = staged[i];
    return PREFIX_BYTES;
}
