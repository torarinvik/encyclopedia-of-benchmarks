#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <optional>
#include <string_view>

namespace {
constexpr int text_limit = 32;
constexpr int pad = 5;
constexpr int key_limit = 4;

struct Encoder {
    std::array<std::uint8_t, text_limit + pad> text{};
    std::array<std::uint8_t, key_limit> primary{};
    std::array<std::uint8_t, key_limit> secondary{};
    std::uint8_t length{};
    std::uint8_t primary_size{};
    std::uint8_t secondary_size{};
    bool alternate_seen{};

    std::uint8_t at(int index) const noexcept {
        return index >= 0 && index < static_cast<int>(text.size()) ? text[index] : ' ';
    }

    bool has(int index, std::string_view token) const noexcept {
        return index >= 0 && static_cast<std::size_t>(index) + token.size() <= text.size() &&
               std::memcmp(text.data() + index, token.data(), token.size()) == 0;
    }

    bool vowel(int index) const noexcept {
        if (index < 0 || index >= length) return false;
        const auto ch = at(index);
        return ch == 'A' || ch == 'E' || ch == 'I' || ch == 'O' || ch == 'U' || ch == 'Y';
    }

    bool slavo_germanic() const noexcept {
        for (int i = 0; i < length; ++i)
            if (at(i) == 'W' || at(i) == 'K' || has(i, "CZ") || has(i, "WITZ")) return true;
        return false;
    }

    static void append(std::array<std::uint8_t, key_limit>& target,
                       std::uint8_t& size, std::string_view fragment) noexcept {
        for (const char ch : fragment) {
            if (size == key_limit) break;
            target[size++] = static_cast<std::uint8_t>(ch);
        }
    }

    void emit(std::string_view main, std::optional<std::string_view> other = std::nullopt) noexcept {
        append(primary, primary_size, main);
        if (!other) {
            append(secondary, secondary_size, main);
            return;
        }
        if (!other->empty()) {
            alternate_seen = true;
            if (other->front() != ' ') append(secondary, secondary_size, *other);
        } else if (!main.empty() && main.front() != ' ') {
            append(secondary, secondary_size, main);
        }
    }

    int c_rule(int i) noexcept {
        if (i > 1 && !vowel(i - 2) && has(i - 1, "ACH") && at(i + 2) != 'I' &&
            (at(i + 2) != 'E' || has(i - 2, "BACHER") || has(i - 2, "MACHER"))) {
            emit("K"); return i + 2;
        }
        if (i == 0 && has(i, "CAESAR")) { emit("S"); return i + 2; }
        if (has(i, "CHIA")) { emit("K"); return i + 2; }
        if (has(i, "CH")) {
            if (i > 0 && has(i, "CHAE")) { emit("K", "X"); return i + 2; }
            if (i == 0 && (has(i + 1, "HARAC") || has(i + 1, "HARIS") || has(i + 1, "HOR") ||
                           has(i + 1, "HYM") || has(i + 1, "HIA") || has(i + 1, "HEM")) &&
                !has(0, "CHORE")) { emit("K"); return i + 2; }
            const bool hard = has(0, "VAN ") || has(0, "VON ") || has(0, "SCH") ||
                has(i - 2, "ORCHES") || has(i - 2, "ARCHIT") || has(i - 2, "ORCHID") ||
                at(i + 2) == 'T' || at(i + 2) == 'S' ||
                ((at(i - 1) == 'A' || at(i - 1) == 'O' || at(i - 1) == 'U' || at(i - 1) == 'E' || i == 0) &&
                 (at(i + 2) == 'L' || at(i + 2) == 'R' || at(i + 2) == 'N' || at(i + 2) == 'M' ||
                  at(i + 2) == 'B' || at(i + 2) == 'H' || at(i + 2) == 'F' || at(i + 2) == 'V' ||
                  at(i + 2) == 'W' || at(i + 2) == ' '));
            if (hard) emit("K");
            else if (i > 0) {
                if (has(0, "MC")) emit("K"); else emit("X", "K");
            } else emit("X");
            return i + 2;
        }
        if (has(i, "CZ") && !has(i - 2, "WICZ")) { emit("S", "X"); return i + 2; }
        if (has(i + 1, "CIA")) { emit("X"); return i + 3; }
        if (has(i, "CC") && !(i == 1 && at(0) == 'M')) {
            if ((at(i + 2) == 'I' || at(i + 2) == 'E' || at(i + 2) == 'H') && !has(i + 2, "HU")) {
                if ((i == 1 && at(i - 1) == 'A') || has(i - 1, "UCCEE") || has(i - 1, "UCCES")) emit("KS");
                else emit("X");
                return i + 3;
            }
            emit("K"); return i + 2;
        }
        if (has(i, "CK") || has(i, "CG") || has(i, "CQ")) { emit("K"); return i + 2; }
        if (has(i, "CI") || has(i, "CE") || has(i, "CY")) {
            if (has(i, "CIO") || has(i, "CIE") || has(i, "CIA")) emit("S", "X"); else emit("S");
            return i + 2;
        }
        emit("K");
        if (has(i + 1, " C") || has(i + 1, " Q") || has(i + 1, " G")) return i + 3;
        if ((at(i + 1) == 'C' || at(i + 1) == 'K' || at(i + 1) == 'Q') &&
            !has(i + 1, "CE") && !has(i + 1, "CI")) return i + 2;
        return i + 1;
    }

    int g_rule(int i, bool slavo) noexcept {
        if (at(i + 1) == 'H') {
            if (i > 0 && !vowel(i - 1)) { emit("K"); return i + 2; }
            if (i == 0) { emit(at(i + 2) == 'I' ? "J" : "K"); return i + 2; }
            if ((i > 1 && (at(i - 2) == 'B' || at(i - 2) == 'H' || at(i - 2) == 'D')) ||
                (i > 2 && (at(i - 3) == 'B' || at(i - 3) == 'H' || at(i - 3) == 'D')) ||
                (i > 3 && (at(i - 4) == 'B' || at(i - 4) == 'H'))) return i + 2;
            if (i > 2 && at(i - 1) == 'U' &&
                (at(i - 3) == 'C' || at(i - 3) == 'G' || at(i - 3) == 'L' || at(i - 3) == 'R' || at(i - 3) == 'T')) emit("F");
            else if (i > 0 && at(i - 1) != 'I') emit("K");
            return i + 2;
        }
        if (at(i + 1) == 'N') {
            if (i == 1 && vowel(0) && !slavo) emit("KN", "N");
            else if (!has(i + 2, "EY") && at(i + 1) != 'Y' && !slavo) emit("N", "KN");
            else emit("KN");
            return i + 2;
        }
        if (has(i + 1, "LI") && !slavo) { emit("KL", "L"); return i + 2; }
        if (i == 0 && (at(i + 1) == 'Y' || has(i + 1, "ES") || has(i + 1, "EP") ||
            has(i + 1, "EB") || has(i + 1, "EL") || has(i + 1, "EY") || has(i + 1, "IB") ||
            has(i + 1, "IL") || has(i + 1, "IN") || has(i + 1, "IE") || has(i + 1, "EI") || has(i + 1, "ER"))) {
            emit("K", "J"); return i + 2;
        }
        if ((has(i + 1, "ER") || at(i + 1) == 'Y') && !has(0, "DANGER") && !has(0, "RANGER") &&
            !has(0, "MANGER") && at(i - 1) != 'E' && at(i - 1) != 'I' && !has(i - 1, "RGY") && !has(i - 1, "OGY")) {
            emit("K", "J"); return i + 2;
        }
        if (at(i + 1) == 'E' || at(i + 1) == 'I' || at(i + 1) == 'Y' || has(i - 1, "AGGI") || has(i - 1, "OGGI")) {
            if (has(0, "VAN ") || has(0, "VON ") || has(0, "SCH") || has(i + 1, "ET")) emit("K");
            else if (has(i + 1, "IER ")) emit("J");
            else emit("J", "K");
            return i + 2;
        }
        emit("K"); return i + (at(i + 1) == 'G' ? 2 : 1);
    }

    int j_rule(int i, bool slavo) noexcept {
        if (has(i, "JOSE") || has(0, "SAN ")) {
            if ((i == 0 && at(i + 4) == ' ') || has(0, "SAN ")) emit("H"); else emit("J", "H");
            return i + 1;
        }
        if (i == 0) emit("J", "A");
        else if (vowel(i - 1) && !slavo && (at(i + 1) == 'A' || at(i + 1) == 'O')) emit("J", "H");
        else if (i == length - 1) emit("J", " ");
        else if (!(at(i + 1) == 'L' || at(i + 1) == 'T' || at(i + 1) == 'K' || at(i + 1) == 'S' ||
                   at(i + 1) == 'N' || at(i + 1) == 'M' || at(i + 1) == 'B' || at(i + 1) == 'Z') &&
                 at(i - 1) != 'S' && at(i - 1) != 'K' && at(i - 1) != 'L') emit("J");
        return i + (at(i + 1) == 'J' ? 2 : 1);
    }

    int l_rule(int i) noexcept {
        if (at(i + 1) != 'L') { emit("L"); return i + 1; }
        const bool spanish = (i == length - 3 && (has(i - 1, "ILLO") || has(i - 1, "ILLA") || has(i - 1, "ALLE"))) ||
            ((has(length - 3, "AS") || has(length - 3, "OS") || at(length - 1) == 'A' || at(length - 1) == 'O') && has(i - 1, "ALLE"));
        if (spanish) emit("L", " "); else emit("L");
        return i + 2;
    }

    int s_rule(int i, bool slavo) noexcept {
        if (has(i - 1, "ISL") || has(i - 1, "YSL")) return i + 1;
        if (i == 0 && has(i, "SUGAR")) { emit("X", "S"); return i + 1; }
        if (has(i, "SH")) {
            if (has(i + 1, "HEIM") || has(i + 1, "HOEK") || has(i + 1, "HOLM") || has(i + 1, "HOLZ")) emit("S");
            else emit("X");
            return i + 2;
        }
        if (has(i, "SIO") || has(i, "SIA") || has(i, "SIAN")) {
            if (!slavo) emit("S", "X"); else emit("S");
            return i + 3;
        }
        if ((i == 0 && (at(i + 1) == 'M' || at(i + 1) == 'N' || at(i + 1) == 'L' || at(i + 1) == 'W')) || at(i + 1) == 'Z') {
            emit("S", "X"); return i + (at(i + 1) == 'Z' ? 2 : 1);
        }
        if (has(i, "SC")) {
            if (at(i + 2) == 'H') {
                if (has(i + 3, "OO") || has(i + 3, "ER") || has(i + 3, "EN") || has(i + 3, "UY") || has(i + 3, "ED") || has(i + 3, "EM")) {
                    if (has(i + 3, "ER") || has(i + 3, "EN")) emit("X", "SK"); else emit("SK");
                } else if (i == 0 && !vowel(3) && at(3) != 'W') emit("X", "S");
                else emit("X");
                return i + 3;
            }
            if (at(i + 2) == 'I' || at(i + 2) == 'E' || at(i + 2) == 'Y') emit("S"); else emit("SK");
            return i + 3;
        }
        if (i == length - 1 && (has(i - 2, "AI") || has(i - 2, "OI"))) emit("", "S"); else emit("S");
        return i + ((at(i + 1) == 'S' || at(i + 1) == 'Z') ? 2 : 1);
    }

    int t_rule(int i) noexcept {
        if (has(i, "TION")) { emit("X"); return i + 3; }
        if (has(i, "TIA") || has(i, "TCH")) { emit("X"); return i + 3; }
        if (has(i, "TH") || has(i, "TTH")) {
            if (has(i + 2, "OM") || has(i + 2, "AM") || has(0, "VAN ") || has(0, "VON ") || has(0, "SCH")) emit("T");
            else emit("0", "T");
            return i + 2;
        }
        emit("T"); return i + ((at(i + 1) == 'T' || at(i + 1) == 'D') ? 2 : 1);
    }

    int w_rule(int i) noexcept {
        if (has(i, "WR")) { emit("R"); return i + 2; }
        if (i == 0 && (vowel(i + 1) || has(i, "WH"))) {
            if (vowel(i + 1)) emit("A", "F"); else emit("A");
        }
        if ((i == length - 1 && vowel(i - 1)) || has(i - 1, "EWSKI") || has(i - 1, "EWSKY") ||
            has(i - 1, "OWSKI") || has(i - 1, "OWSKY") || has(0, "SCH")) {
            emit("", "F"); return i + 1;
        }
        if (has(i, "WICZ") || has(i, "WITZ")) { emit("TS", "FX"); return i + 4; }
        return i + 1;
    }
};

std::uint8_t uppercase(std::uint8_t value) noexcept {
    if (value >= 'a' && value <= 'z') return static_cast<std::uint8_t>(value - ('a' - 'A'));
    if (value == 0xE7) return 0xC7;
    if (value == 0xF1) return 0xD1;
    return value;
}

bool accepted(std::int64_t value) noexcept {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == ' ' ||
           value == 0xC7 || value == 0xE7 || value == 0xD1 || value == 0xF1;
}
} // namespace

extern "C" std::int64_t double_metaphone(const std::int64_t* values, std::size_t length,
                                          std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || length > 34 || values[0] < 0 || values[0] > text_limit) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != count + 1) return -1;
    Encoder encoder{};
    encoder.text.fill(' ');
    encoder.length = static_cast<std::uint8_t>(count);
    for (std::size_t i = 0; i < count; ++i) {
        if (!accepted(values[i + 1])) return -1;
        encoder.text[i] = uppercase(static_cast<std::uint8_t>(values[i + 1]));
    }
    const bool slavo = encoder.slavo_germanic();
    int index = 0;
    if (encoder.has(0, "GN") || encoder.has(0, "KN") || encoder.has(0, "PN") ||
        encoder.has(0, "WR") || encoder.has(0, "PS")) index = 1;
    if (encoder.at(0) == 'X') { encoder.emit("S"); index = 1; }

    while (index < encoder.length &&
           (encoder.primary_size < key_limit || encoder.secondary_size < key_limit)) {
        switch (encoder.at(index)) {
        case 'A': case 'E': case 'I': case 'O': case 'U': case 'Y':
            if (index == 0) encoder.emit("A"); ++index; break;
        case 'B': encoder.emit("P"); index += encoder.at(index + 1) == 'B' ? 2 : 1; break;
        case 0xC7: encoder.emit("S"); ++index; break;
        case 'C': index = encoder.c_rule(index); break;
        case 'D':
            if (encoder.has(index, "DG")) {
                if (encoder.at(index + 2) == 'I' || encoder.at(index + 2) == 'E' || encoder.at(index + 2) == 'Y') {
                    encoder.emit("J"); index += 3;
                } else { encoder.emit("TK"); index += 2; }
            } else if (encoder.has(index, "DT") || encoder.has(index, "DD")) { encoder.emit("T"); index += 2; }
            else { encoder.emit("T"); ++index; }
            break;
        case 'F': encoder.emit("F"); index += encoder.at(index + 1) == 'F' ? 2 : 1; break;
        case 'G': index = encoder.g_rule(index, slavo); break;
        case 'H':
            if ((index == 0 || encoder.vowel(index - 1)) && encoder.vowel(index + 1)) { encoder.emit("H"); index += 2; }
            else ++index;
            break;
        case 'J': index = encoder.j_rule(index, slavo); break;
        case 'K': encoder.emit("K"); index += encoder.at(index + 1) == 'K' ? 2 : 1; break;
        case 'L': index = encoder.l_rule(index); break;
        case 'M':
            if ((encoder.has(index - 1, "UMB") && (index + 1 == encoder.length - 1 || encoder.has(index + 2, "ER"))) ||
                encoder.at(index + 1) == 'M') index += 2; else ++index;
            encoder.emit("M"); break;
        case 'N': encoder.emit("N"); index += encoder.at(index + 1) == 'N' ? 2 : 1; break;
        case 0xD1: encoder.emit("N"); ++index; break;
        case 'P':
            if (encoder.at(index + 1) == 'H') { encoder.emit("F"); index += 2; }
            else { encoder.emit("P"); index += (encoder.at(index + 1) == 'P' || encoder.at(index + 1) == 'B') ? 2 : 1; }
            break;
        case 'Q': encoder.emit("K"); index += encoder.at(index + 1) == 'Q' ? 2 : 1; break;
        case 'R':
            if (index == encoder.length - 1 && !slavo && encoder.has(index - 2, "IE") &&
                !encoder.has(index - 4, "ME") && !encoder.has(index - 4, "MA")) encoder.emit("", "R");
            else encoder.emit("R");
            index += encoder.at(index + 1) == 'R' ? 2 : 1; break;
        case 'S': index = encoder.s_rule(index, slavo); break;
        case 'T': index = encoder.t_rule(index); break;
        case 'V': encoder.emit("F"); index += encoder.at(index + 1) == 'V' ? 2 : 1; break;
        case 'W': index = encoder.w_rule(index); break;
        case 'X': {
            const bool french = index == encoder.length - 1 &&
                (encoder.has(index - 3, "IAU") || encoder.has(index - 3, "EAU") ||
                 encoder.has(index - 2, "AU") || encoder.has(index - 2, "OU"));
            if (!french) encoder.emit("KS");
            index += (encoder.at(index + 1) == 'C' || encoder.at(index + 1) == 'X') ? 2 : 1;
            break;
        }
        case 'Z':
            if (encoder.at(index + 1) == 'H') { encoder.emit("J"); index += 2; break; }
            if (encoder.has(index + 1, "ZO") || encoder.has(index + 1, "ZI") || encoder.has(index + 1, "ZA") ||
                (slavo && index > 0 && encoder.at(index - 1) != 'T')) encoder.emit("S", "TS");
            else encoder.emit("S");
            index += encoder.at(index + 1) == 'Z' ? 2 : 1; break;
        default: ++index; break;
        }
    }

    std::size_t second_size = encoder.alternate_seen ? encoder.secondary_size : 0;
    if (second_size == encoder.primary_size &&
        std::memcmp(encoder.primary.data(), encoder.secondary.data(), encoder.primary_size) == 0) second_size = 0;
    const std::size_t required = 2 + encoder.primary_size + second_size;
    if (output == nullptr || output_capacity < required) return -2;
    output[0] = encoder.primary_size;
    output[1] = static_cast<std::uint8_t>(second_size);
    std::memcpy(output + 2, encoder.primary.data(), encoder.primary_size);
    if (second_size != 0) std::memcpy(output + 2 + encoder.primary_size, encoder.secondary.data(), second_size);
    return static_cast<std::int64_t>(required);
}
