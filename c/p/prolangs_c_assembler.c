/* (c) William Landi 1991
 * Permission to use this code is granted as long as the copyright
 * notice remains in place.
 *
 * Clean-room bounded adaptation: numeric records replace the original text,
 * temporary-file, listing, and object-file interfaces; the two-pass symbol
 * and SIC/XE encoding behavior is retained for the documented subset.
 */
#include <stddef.h>
#include <stdint.h>

enum { MAX_RECORDS = 16, MAX_LABELS = 16, MAX_INPUT = 65 };
static const int64_t MODULUS = INT64_C(1000000007);

int64_t prolangs_c_assembler(const int64_t *input, size_t length)
{
    if (input == NULL || length < 9 || length > MAX_INPUT) return -1;
    if (input[0] < 2 || input[0] > MAX_RECORDS) return -1;
    const int count = (int)input[0];
    if (length != 1 + (size_t)count * 4) return -1;

    int opcode[MAX_RECORDS], label[MAX_RECORDS], kind[MAX_RECORDS], operand[MAX_RECORDS];
    int address[MAX_RECORDS] = {0}, size[MAX_RECORDS] = {0};
    int64_t code[MAX_RECORDS] = {0}, symbol[MAX_LABELS + 1] = {0};
    int defined[MAX_LABELS + 1] = {0};
    for (int i = 0; i < count; ++i) {
        const size_t offset = 1 + (size_t)i * 4;
        if (input[offset] < 0 || input[offset] > 11 || input[offset + 1] < 0 || input[offset + 1] > MAX_LABELS ||
            input[offset + 2] < 0 || input[offset + 2] > 5 || input[offset + 3] < 0 || input[offset + 3] > 0xFFFFFF) return -1;
        opcode[i] = (int)input[offset]; label[i] = (int)input[offset + 1];
        kind[i] = (int)input[offset + 2]; operand[i] = (int)input[offset + 3];
    }
    if (opcode[0] != 0 || opcode[count - 1] != 1 || label[0] == 0 || kind[0] != 0 || operand[0] > 0xFFFFF) return -1;
    for (int i = 1; i < count - 1; ++i) if (opcode[i] == 0 || opcode[i] == 1) return -1;
    if (label[count - 1] != 0 || kind[count - 1] != 0 || operand[count - 1] != 0) return -1;

    int location = operand[0];
    const int start_address = location;
    address[0] = location;
    defined[label[0]] = 1;
    symbol[label[0]] = location;
    for (int i = 0; i < count; ++i) {
        if (i > 0) {
            address[i] = location;
            if (label[i] != 0) {
                if (defined[label[i]] || location >= 0x100000) return -1;
                defined[label[i]] = 1;
                symbol[label[i]] = location;
            }
        }
        switch (opcode[i]) {
        case 0:
            if (i != 0) return -1;
            size[i] = 0;
            break;
        case 1:
            if (i != count - 1) return -1;
            size[i] = 0;
            break;
        case 2:
            if (kind[i] != 0 || operand[i] > 256) return -1;
            size[i] = operand[i];
            break;
        case 3:
            if (kind[i] != 0 || operand[i] > 256) return -1;
            size[i] = operand[i] * 3;
            break;
        case 4:
            if (kind[i] != 0) return -1;
            size[i] = 3;
            break;
        case 5: case 6: case 7: case 8:
            if (!((kind[i] == 1 && operand[i] <= 4095) ||
                  ((kind[i] == 2 || kind[i] == 3) && operand[i] >= 1 && operand[i] <= MAX_LABELS))) return -1;
            size[i] = 3;
            break;
        case 9:
            if (kind[i] != 0 || operand[i] != 0) return -1;
            size[i] = 3;
            break;
        case 10:
            if (kind[i] != 4 || operand[i] > 5) return -1;
            size[i] = 2;
            break;
        case 11:
            if (kind[i] != 5 || (operand[i] >> 4) > 5 || (operand[i] & 15) > 5) return -1;
            size[i] = 2;
            break;
        default: return -1;
        }
        if (i != 0) {
            if (location > 0x100000 - size[i]) return -1;
            location += size[i];
        }
    }
    const int program_length = location - start_address;

    for (int i = 1; i < count - 1; ++i) {
        switch (opcode[i]) {
        case 4:
            code[i] = operand[i];
            break;
        case 5: case 6: case 7: case 8: {
            const int base = opcode[i] == 5 ? 0x00 : opcode[i] == 6 ? 0x0C : opcode[i] == 7 ? 0x18 : 0x3C;
            const int ni = kind[i] == 1 ? 1 : kind[i] == 2 ? 3 : 2;
            int field = operand[i];
            int pc_relative = 0;
            if (kind[i] == 2 || kind[i] == 3) {
                if (!defined[operand[i]]) return -1;
                field = (int)symbol[operand[i]] - (address[i] + 3);
                if (field < -2048 || field > 2047) return -1;
                pc_relative = 1;
                field &= 0xFFF;
            }
            code[i] = (int64_t)(base | ni) * 65536 + (int64_t)pc_relative * 8192 + field;
            break;
        }
        case 9:
            code[i] = INT64_C(0x4F0000);
            break;
        case 10:
            code[i] = INT64_C(0xB400) | ((int64_t)operand[i] << 4);
            break;
        case 11:
            code[i] = INT64_C(0x9000) | operand[i];
            break;
        default: break;
        }
    }

    int64_t checksum = ((int64_t)program_length * 257 + (int64_t)start_address * 17) % MODULUS;
    for (int i = 0; i < count; ++i)
        checksum = (checksum * 131 + (int64_t)(address[i] + 1) * 17 + code[i] * 3 + size[i]) % MODULUS;
    return checksum;
}
