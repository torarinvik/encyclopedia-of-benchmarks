/* (c) William Landi 1991
 * Permission to use this code is granted as long as the copyright
 * notice remains in place.
 *
 * Clean-room bounded adaptation: numeric records replace the original text,
 * temporary-file, listing, and object-file interfaces; the two-pass symbol
 * and SIC/XE encoding behavior is retained for the documented subset.
 */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_records = 16, max_labels = 16;
constexpr std::int64_t modulus = 1000000007;
}

extern "C" std::int64_t prolangs_c_assembler(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 9 || length > 65 || input[0] < 2 || input[0] > max_records) return -1;
    const int count = static_cast<int>(input[0]);
    if (length != 1 + static_cast<std::size_t>(count) * 4) return -1;
    std::array<int, max_records> opcode{}, label{}, kind{}, operand{}, address{}, size{};
    std::array<std::int64_t, max_records> code{};
    std::array<std::int64_t, max_labels + 1> symbol{};
    std::array<bool, max_labels + 1> defined{};
    for (int i = 0; i < count; ++i) {
        const std::size_t offset = 1 + static_cast<std::size_t>(i) * 4;
        if (input[offset] < 0 || input[offset] > 11 || input[offset + 1] < 0 || input[offset + 1] > max_labels ||
            input[offset + 2] < 0 || input[offset + 2] > 5 || input[offset + 3] < 0 || input[offset + 3] > 0xFFFFFF) return -1;
        opcode[i] = static_cast<int>(input[offset]); label[i] = static_cast<int>(input[offset + 1]);
        kind[i] = static_cast<int>(input[offset + 2]); operand[i] = static_cast<int>(input[offset + 3]);
    }
    if (opcode[0] != 0 || opcode[count - 1] != 1 || label[0] == 0 || kind[0] != 0 || operand[0] > 0xFFFFF) return -1;
    for (int i = 1; i < count - 1; ++i) if (opcode[i] == 0 || opcode[i] == 1) return -1;
    if (label[count - 1] != 0 || kind[count - 1] != 0 || operand[count - 1] != 0) return -1;

    int location = operand[0];
    const int start_address = location;
    address[0] = location;
    defined[label[0]] = true;
    symbol[label[0]] = location;
    for (int i = 0; i < count; ++i) {
        if (i > 0) {
            address[i] = location;
            if (label[i] != 0) {
                if (defined[label[i]] || location >= 0x100000) return -1;
                defined[label[i]] = true;
                symbol[label[i]] = location;
            }
        }
        switch (opcode[i]) {
        case 0: if (i != 0) return -1; size[i] = 0; break;
        case 1: if (i != count - 1) return -1; size[i] = 0; break;
        case 2: if (kind[i] != 0 || operand[i] > 256) return -1; size[i] = operand[i]; break;
        case 3: if (kind[i] != 0 || operand[i] > 256) return -1; size[i] = operand[i] * 3; break;
        case 4: if (kind[i] != 0) return -1; size[i] = 3; break;
        case 5: case 6: case 7: case 8:
            if (!((kind[i] == 1 && operand[i] <= 4095) || ((kind[i] == 2 || kind[i] == 3) && operand[i] >= 1 && operand[i] <= max_labels))) return -1;
            size[i] = 3; break;
        case 9: if (kind[i] != 0 || operand[i] != 0) return -1; size[i] = 3; break;
        case 10: if (kind[i] != 4 || operand[i] > 5) return -1; size[i] = 2; break;
        case 11: if (kind[i] != 5 || (operand[i] >> 4) > 5 || (operand[i] & 15) > 5) return -1; size[i] = 2; break;
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
        case 4: code[i] = operand[i]; break;
        case 5: case 6: case 7: case 8: {
            const int base = opcode[i] == 5 ? 0x00 : opcode[i] == 6 ? 0x0C : opcode[i] == 7 ? 0x18 : 0x3C;
            const int ni = kind[i] == 1 ? 1 : kind[i] == 2 ? 3 : 2;
            int field = operand[i], pc_relative = 0;
            if (kind[i] == 2 || kind[i] == 3) {
                if (!defined[operand[i]]) return -1;
                field = static_cast<int>(symbol[operand[i]]) - (address[i] + 3);
                if (field < -2048 || field > 2047) return -1;
                pc_relative = 1;
                field &= 0xFFF;
            }
            code[i] = static_cast<std::int64_t>(base | ni) * 65536 + static_cast<std::int64_t>(pc_relative) * 8192 + field;
            break;
        }
        case 9: code[i] = 0x4F0000; break;
        case 10: code[i] = 0xB400 | (static_cast<std::int64_t>(operand[i]) << 4); break;
        case 11: code[i] = 0x9000 | operand[i]; break;
        default: break;
        }
    }
    std::int64_t checksum = (static_cast<std::int64_t>(program_length) * 257 + static_cast<std::int64_t>(start_address) * 17) % modulus;
    for (int i = 0; i < count; ++i)
        checksum = (checksum * 131 + static_cast<std::int64_t>(address[i] + 1) * 17 + code[i] * 3 + size[i]) % modulus;
    return checksum;
}
