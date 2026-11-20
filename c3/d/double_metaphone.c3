module double_metaphone;

const usz TEXT_LIMIT = 32;
const usz INPUT_LIMIT = 33;
const usz PAD = 5;
const usz KEY_LIMIT = 4;

struct Encoder {
    uchar[37] text;
    uchar[4] primary;
    uchar[4] secondary;
    uchar length;
    uchar primary_length;
    uchar secondary_length;
    bool alternate_seen;
}

fn uchar at(Encoder* state, int index) {
    if (index < 0 || index >= 37) return ' ';
    return state.text[(usz)index];
}

fn bool has(Encoder* state, int index, const char* pattern) {
    if (index < 0) return false;
    usz size = 0;
    while (pattern[size] != 0) size++;
    usz start = (usz)index;
    if (start + size > 37) return false;
    for (usz i = 0; i < size; i++)
        if (state.text[start + i] != (uchar)pattern[i]) return false;
    return true;
}

fn bool vowel(Encoder* state, int index) {
    if (index < 0 || index >= (int)state.length) return false;
    uchar ch = at(state, index);
    return ch == 'A' || ch == 'E' || ch == 'I' || ch == 'O' || ch == 'U' || ch == 'Y';
}

fn void append(uchar[4]* target, uchar* size, const char* fragment) {
    usz i = 0;
    while (fragment[i] != 0 && *size < 4) {
        target[*size] = (uchar)fragment[i];
        *size += 1;
        i++;
    }
}

fn void emit(Encoder* state, const char* main, const char* other = null) {
    append(&state.primary, &state.primary_length, main);
    if (other == null) {
        append(&state.secondary, &state.secondary_length, main);
        return;
    }
    if (other[0] != 0) {
        state.alternate_seen = true;
        if (other[0] != ' ') append(&state.secondary, &state.secondary_length, other);
    } else if (main[0] != 0 && main[0] != ' ') {
        append(&state.secondary, &state.secondary_length, main);
    }
}

fn bool slavo_germanic(Encoder* state) {
    for (int i = 0; i < (int)state.length; i++)
        if (at(state, i) == 'W' || at(state, i) == 'K' || has(state, i, "CZ") || has(state, i, "WITZ")) return true;
    return false;
}

fn int c_rule(Encoder* state, int i) {
    if (i > 1 && !vowel(state, i - 2) && has(state, i - 1, "ACH") && at(state, i + 2) != 'I' &&
        (at(state, i + 2) != 'E' || has(state, i - 2, "BACHER") || has(state, i - 2, "MACHER"))) {
        emit(state, "K"); return i + 2;
    }
    if (i == 0 && has(state, i, "CAESAR")) { emit(state, "S"); return i + 2; }
    if (has(state, i, "CHIA")) { emit(state, "K"); return i + 2; }
    if (has(state, i, "CH")) {
        if (i > 0 && has(state, i, "CHAE")) { emit(state, "K", "X"); return i + 2; }
        if (i == 0 && (has(state, i + 1, "HARAC") || has(state, i + 1, "HARIS") || has(state, i + 1, "HOR") ||
            has(state, i + 1, "HYM") || has(state, i + 1, "HIA") || has(state, i + 1, "HEM")) && !has(state, 0, "CHORE")) {
            emit(state, "K"); return i + 2;
        }
        bool hard = has(state, 0, "VAN ") || has(state, 0, "VON ") || has(state, 0, "SCH") ||
            has(state, i - 2, "ORCHES") || has(state, i - 2, "ARCHIT") || has(state, i - 2, "ORCHID") ||
            at(state, i + 2) == 'T' || at(state, i + 2) == 'S' ||
            ((at(state, i - 1) == 'A' || at(state, i - 1) == 'O' || at(state, i - 1) == 'U' || at(state, i - 1) == 'E' || i == 0) &&
             (at(state, i + 2) == 'L' || at(state, i + 2) == 'R' || at(state, i + 2) == 'N' || at(state, i + 2) == 'M' ||
              at(state, i + 2) == 'B' || at(state, i + 2) == 'H' || at(state, i + 2) == 'F' || at(state, i + 2) == 'V' ||
              at(state, i + 2) == 'W' || at(state, i + 2) == ' '));
        if (hard) emit(state, "K");
        else if (i > 0) {
            if (has(state, 0, "MC")) emit(state, "K"); else emit(state, "X", "K");
        } else emit(state, "X");
        return i + 2;
    }
    if (has(state, i, "CZ") && !has(state, i - 2, "WICZ")) { emit(state, "S", "X"); return i + 2; }
    if (has(state, i + 1, "CIA")) { emit(state, "X"); return i + 3; }
    if (has(state, i, "CC") && !(i == 1 && at(state, 0) == 'M')) {
        if ((at(state, i + 2) == 'I' || at(state, i + 2) == 'E' || at(state, i + 2) == 'H') && !has(state, i + 2, "HU")) {
            if ((i == 1 && at(state, i - 1) == 'A') || has(state, i - 1, "UCCEE") || has(state, i - 1, "UCCES")) emit(state, "KS");
            else emit(state, "X");
            return i + 3;
        }
        emit(state, "K"); return i + 2;
    }
    if (has(state, i, "CK") || has(state, i, "CG") || has(state, i, "CQ")) { emit(state, "K"); return i + 2; }
    if (has(state, i, "CI") || has(state, i, "CE") || has(state, i, "CY")) {
        if (has(state, i, "CIO") || has(state, i, "CIE") || has(state, i, "CIA")) emit(state, "S", "X");
        else emit(state, "S");
        return i + 2;
    }
    emit(state, "K");
    if (has(state, i + 1, " C") || has(state, i + 1, " Q") || has(state, i + 1, " G")) return i + 3;
    if ((at(state, i + 1) == 'C' || at(state, i + 1) == 'K' || at(state, i + 1) == 'Q') &&
        !has(state, i + 1, "CE") && !has(state, i + 1, "CI")) return i + 2;
    return i + 1;
}

fn int g_rule(Encoder* state, int i, bool slavo) {
    if (at(state, i + 1) == 'H') {
        if (i > 0 && !vowel(state, i - 1)) { emit(state, "K"); return i + 2; }
        if (i == 0) { if (at(state, i + 2) == 'I') emit(state, "J"); else emit(state, "K"); return i + 2; }
        if ((i > 1 && (at(state, i - 2) == 'B' || at(state, i - 2) == 'H' || at(state, i - 2) == 'D')) ||
            (i > 2 && (at(state, i - 3) == 'B' || at(state, i - 3) == 'H' || at(state, i - 3) == 'D')) ||
            (i > 3 && (at(state, i - 4) == 'B' || at(state, i - 4) == 'H'))) return i + 2;
        if (i > 2 && at(state, i - 1) == 'U' &&
            (at(state, i - 3) == 'C' || at(state, i - 3) == 'G' || at(state, i - 3) == 'L' || at(state, i - 3) == 'R' || at(state, i - 3) == 'T')) emit(state, "F");
        else if (i > 0 && at(state, i - 1) != 'I') emit(state, "K");
        return i + 2;
    }
    if (at(state, i + 1) == 'N') {
        if (i == 1 && vowel(state, 0) && !slavo) emit(state, "KN", "N");
        else if (!has(state, i + 2, "EY") && at(state, i + 1) != 'Y' && !slavo) emit(state, "N", "KN");
        else emit(state, "KN");
        return i + 2;
    }
    if (has(state, i + 1, "LI") && !slavo) { emit(state, "KL", "L"); return i + 2; }
    if (i == 0 && (at(state, i + 1) == 'Y' || has(state, i + 1, "ES") || has(state, i + 1, "EP") ||
        has(state, i + 1, "EB") || has(state, i + 1, "EL") || has(state, i + 1, "EY") ||
        has(state, i + 1, "IB") || has(state, i + 1, "IL") || has(state, i + 1, "IN") ||
        has(state, i + 1, "IE") || has(state, i + 1, "EI") || has(state, i + 1, "ER"))) {
        emit(state, "K", "J"); return i + 2;
    }
    if ((has(state, i + 1, "ER") || at(state, i + 1) == 'Y') && !has(state, 0, "DANGER") && !has(state, 0, "RANGER") &&
        !has(state, 0, "MANGER") && at(state, i - 1) != 'E' && at(state, i - 1) != 'I' && !has(state, i - 1, "RGY") && !has(state, i - 1, "OGY")) {
        emit(state, "K", "J"); return i + 2;
    }
    if (at(state, i + 1) == 'E' || at(state, i + 1) == 'I' || at(state, i + 1) == 'Y' || has(state, i - 1, "AGGI") || has(state, i - 1, "OGGI")) {
        if (has(state, 0, "VAN ") || has(state, 0, "VON ") || has(state, 0, "SCH") || has(state, i + 1, "ET")) emit(state, "K");
        else if (has(state, i + 1, "IER ")) emit(state, "J");
        else emit(state, "J", "K");
        return i + 2;
    }
    emit(state, "K"); return i + (at(state, i + 1) == 'G' ? 2 : 1);
}

fn int j_rule(Encoder* state, int i, bool slavo) {
    if (has(state, i, "JOSE") || has(state, 0, "SAN ")) {
        if ((i == 0 && at(state, i + 4) == ' ') || has(state, 0, "SAN ")) emit(state, "H");
        else emit(state, "J", "H");
        return i + 1;
    }
    if (i == 0) emit(state, "J", "A");
    else if (vowel(state, i - 1) && !slavo && (at(state, i + 1) == 'A' || at(state, i + 1) == 'O')) emit(state, "J", "H");
    else if (i == (int)state.length - 1) emit(state, "J", " ");
    else if (!(at(state, i + 1) == 'L' || at(state, i + 1) == 'T' || at(state, i + 1) == 'K' || at(state, i + 1) == 'S' ||
        at(state, i + 1) == 'N' || at(state, i + 1) == 'M' || at(state, i + 1) == 'B' || at(state, i + 1) == 'Z') &&
        at(state, i - 1) != 'S' && at(state, i - 1) != 'K' && at(state, i - 1) != 'L') emit(state, "J");
    return i + (at(state, i + 1) == 'J' ? 2 : 1);
}

fn int l_rule(Encoder* state, int i) {
    if (at(state, i + 1) != 'L') { emit(state, "L"); return i + 1; }
    const int n = (int)state.length;
    bool spanish = (i == n - 3 && (has(state, i - 1, "ILLO") || has(state, i - 1, "ILLA") || has(state, i - 1, "ALLE"))) ||
        ((has(state, n - 3, "AS") || has(state, n - 3, "OS") || at(state, n - 1) == 'A' || at(state, n - 1) == 'O') && has(state, i - 1, "ALLE"));
    if (spanish) emit(state, "L", " "); else emit(state, "L");
    return i + 2;
}

fn int s_rule(Encoder* state, int i, bool slavo) {
    if (has(state, i - 1, "ISL") || has(state, i - 1, "YSL")) return i + 1;
    if (i == 0 && has(state, i, "SUGAR")) { emit(state, "X", "S"); return i + 1; }
    if (has(state, i, "SH")) {
        if (has(state, i + 1, "HEIM") || has(state, i + 1, "HOEK") || has(state, i + 1, "HOLM") || has(state, i + 1, "HOLZ")) emit(state, "S");
        else emit(state, "X");
        return i + 2;
    }
    if (has(state, i, "SIO") || has(state, i, "SIA") || has(state, i, "SIAN")) {
        if (!slavo) emit(state, "S", "X"); else emit(state, "S");
        return i + 3;
    }
    if ((i == 0 && (at(state, i + 1) == 'M' || at(state, i + 1) == 'N' || at(state, i + 1) == 'L' || at(state, i + 1) == 'W')) || at(state, i + 1) == 'Z') {
        emit(state, "S", "X"); return i + (at(state, i + 1) == 'Z' ? 2 : 1);
    }
    if (has(state, i, "SC")) {
        if (at(state, i + 2) == 'H') {
            if (has(state, i + 3, "OO") || has(state, i + 3, "ER") || has(state, i + 3, "EN") || has(state, i + 3, "UY") || has(state, i + 3, "ED") || has(state, i + 3, "EM")) {
                if (has(state, i + 3, "ER") || has(state, i + 3, "EN")) emit(state, "X", "SK"); else emit(state, "SK");
            } else if (i == 0 && !vowel(state, 3) && at(state, 3) != 'W') emit(state, "X", "S");
            else emit(state, "X");
            return i + 3;
        }
        if (at(state, i + 2) == 'I' || at(state, i + 2) == 'E' || at(state, i + 2) == 'Y') emit(state, "S"); else emit(state, "SK");
        return i + 3;
    }
    if (i == (int)state.length - 1 && (has(state, i - 2, "AI") || has(state, i - 2, "OI"))) emit(state, "", "S");
    else emit(state, "S");
    return i + (at(state, i + 1) == 'S' || at(state, i + 1) == 'Z' ? 2 : 1);
}

fn int t_rule(Encoder* state, int i) {
    if (has(state, i, "TION")) { emit(state, "X"); return i + 3; }
    if (has(state, i, "TIA") || has(state, i, "TCH")) { emit(state, "X"); return i + 3; }
    if (has(state, i, "TH") || has(state, i, "TTH")) {
        if (has(state, i + 2, "OM") || has(state, i + 2, "AM") || has(state, 0, "VAN ") || has(state, 0, "VON ") || has(state, 0, "SCH")) emit(state, "T");
        else emit(state, "0", "T");
        return i + 2;
    }
    emit(state, "T"); return i + (at(state, i + 1) == 'T' || at(state, i + 1) == 'D' ? 2 : 1);
}

fn int w_rule(Encoder* state, int i) {
    if (has(state, i, "WR")) { emit(state, "R"); return i + 2; }
    if (i == 0 && (vowel(state, i + 1) || has(state, i, "WH"))) {
        if (vowel(state, i + 1)) emit(state, "A", "F"); else emit(state, "A");
    }
    if ((i == (int)state.length - 1 && vowel(state, i - 1)) || has(state, i - 1, "EWSKI") || has(state, i - 1, "EWSKY") ||
        has(state, i - 1, "OWSKI") || has(state, i - 1, "OWSKY") || has(state, 0, "SCH")) {
        emit(state, "", "F"); return i + 1;
    }
    if (has(state, i, "WICZ") || has(state, i, "WITZ")) { emit(state, "TS", "FX"); return i + 4; }
    return i + 1;
}

fn uchar upper_byte(long value) {
    if (value >= 'a' && value <= 'z') return (uchar)(value - ('a' - 'A'));
    if (value == 0xE7) return 0xC7;
    if (value == 0xF1) return 0xD1;
    return (uchar)value;
}

fn bool valid_byte(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == ' ' ||
        value == 0xC7 || value == 0xE7 || value == 0xD1 || value == 0xF1;
}

fn long double_metaphone(long* values, usz length, char* output, usz output_capacity)
        @export("double_metaphone") {
    if (values == null || length < 1 || length > 34) return -1;
    if (values[0] < 0 || values[0] > 32) return -1;
    usz count = (usz)values[0];
    if (length != count + 1) return -1;
    Encoder state = zeroed;
    for (usz i = 0; i < 37; i++) state.text[i] = ' ';
    state.length = (uchar)count;
    for (usz i = 0; i < count; i++) {
        if (!valid_byte(values[i + 1])) return -1;
        state.text[i] = upper_byte(values[i + 1]);
    }
    bool slavo = slavo_germanic(&state);
    int index = 0;
    if (has(&state, 0, "GN") || has(&state, 0, "KN") || has(&state, 0, "PN") || has(&state, 0, "WR") || has(&state, 0, "PS")) index = 1;
    if (at(&state, 0) == 'X') { emit(&state, "S"); index = 1; }
    while (index < (int)state.length && (state.primary_length < 4 || state.secondary_length < 4)) {
        switch (at(&state, index)) {
        case 'A': case 'E': case 'I': case 'O': case 'U': case 'Y':
            if (index == 0) emit(&state, "A"); index += 1; break;
        case 'B': emit(&state, "P"); index += at(&state, index + 1) == 'B' ? 2 : 1; break;
        case 0xC7: emit(&state, "S"); index += 1; break;
        case 'C': index = c_rule(&state, index); break;
        case 'D':
            if (has(&state, index, "DG")) {
                if (at(&state, index + 2) == 'I' || at(&state, index + 2) == 'E' || at(&state, index + 2) == 'Y') { emit(&state, "J"); index += 3; }
                else { emit(&state, "TK"); index += 2; }
            } else if (has(&state, index, "DT") || has(&state, index, "DD")) { emit(&state, "T"); index += 2; }
            else { emit(&state, "T"); index += 1; }
            break;
        case 'F': emit(&state, "F"); index += at(&state, index + 1) == 'F' ? 2 : 1; break;
        case 'G': index = g_rule(&state, index, slavo); break;
        case 'H':
            if ((index == 0 || vowel(&state, index - 1)) && vowel(&state, index + 1)) { emit(&state, "H"); index += 2; }
            else index += 1;
            break;
        case 'J': index = j_rule(&state, index, slavo); break;
        case 'K': emit(&state, "K"); index += at(&state, index + 1) == 'K' ? 2 : 1; break;
        case 'L': index = l_rule(&state, index); break;
        case 'M':
            if ((has(&state, index - 1, "UMB") && (index + 1 == (int)state.length - 1 || has(&state, index + 2, "ER"))) || at(&state, index + 1) == 'M') index += 2;
            else index += 1;
            emit(&state, "M"); break;
        case 'N': emit(&state, "N"); index += at(&state, index + 1) == 'N' ? 2 : 1; break;
        case 0xD1: emit(&state, "N"); index += 1; break;
        case 'P':
            if (at(&state, index + 1) == 'H') { emit(&state, "F"); index += 2; }
            else { emit(&state, "P"); index += at(&state, index + 1) == 'P' || at(&state, index + 1) == 'B' ? 2 : 1; }
            break;
        case 'Q': emit(&state, "K"); index += at(&state, index + 1) == 'Q' ? 2 : 1; break;
        case 'R':
            if (index == (int)state.length - 1 && !slavo && has(&state, index - 2, "IE") && !has(&state, index - 4, "ME") && !has(&state, index - 4, "MA")) emit(&state, "", "R");
            else emit(&state, "R");
            index += at(&state, index + 1) == 'R' ? 2 : 1; break;
        case 'S': index = s_rule(&state, index, slavo); break;
        case 'T': index = t_rule(&state, index); break;
        case 'V': emit(&state, "F"); index += at(&state, index + 1) == 'V' ? 2 : 1; break;
        case 'W': index = w_rule(&state, index); break;
        case 'X': {
            bool french = index == (int)state.length - 1 && (has(&state, index - 3, "IAU") || has(&state, index - 3, "EAU") || has(&state, index - 2, "AU") || has(&state, index - 2, "OU"));
            if (!french) emit(&state, "KS");
            index += at(&state, index + 1) == 'C' || at(&state, index + 1) == 'X' ? 2 : 1;
            break;
        }
        case 'Z':
            if (at(&state, index + 1) == 'H') { emit(&state, "J"); index += 2; break; }
            if (has(&state, index + 1, "ZO") || has(&state, index + 1, "ZI") || has(&state, index + 1, "ZA") ||
                (slavo && index > 0 && at(&state, index - 1) != 'T')) emit(&state, "S", "TS");
            else emit(&state, "S");
            index += at(&state, index + 1) == 'Z' ? 2 : 1; break;
        default: index += 1; break;
        }
    }
    usz second_length = state.alternate_seen ? (usz)state.secondary_length : 0;
    if (second_length == state.primary_length && state.primary_length == state.secondary_length) {
        bool same = true;
        for (usz i = 0; i < state.primary_length; i++) if (state.primary[i] != state.secondary[i]) same = false;
        if (same) second_length = 0;
    }
    usz required = 2 + (usz)state.primary_length + second_length;
    if (output == null || output_capacity < required) return -2;
    output[0] = (char)state.primary_length; output[1] = (char)second_length;
    for (usz i = 0; i < state.primary_length; i++) output[i + 2] = (char)state.primary[i];
    for (usz i = 0; i < second_length; i++) output[i + 2 + state.primary_length] = (char)state.secondary[i];
    return (long)required;
}
