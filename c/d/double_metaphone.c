/* Bounded, clean-room transcription of Philips's original rule behavior. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { DM_TEXT_LIMIT = 32, DM_PAD = 5, DM_KEY_LIMIT = 4, DM_MAX_INPUT = 33 };

typedef struct {
    uint8_t text[DM_TEXT_LIMIT + DM_PAD];
    uint8_t primary[DM_KEY_LIMIT];
    uint8_t secondary[DM_KEY_LIMIT];
    uint8_t length;
    uint8_t primary_length;
    uint8_t secondary_length;
    uint8_t alternate_seen;
} dm_state;

static uint8_t dm_at(const dm_state *state, int index)
{
    return index >= 0 && index < DM_TEXT_LIMIT + DM_PAD ? state->text[index] : (uint8_t)' ';
}

static int dm_has(const dm_state *state, int index, const char *pattern)
{
    const size_t count = strlen(pattern);
    return index >= 0 && (size_t)index + count <= sizeof(state->text) &&
           memcmp(state->text + index, pattern, count) == 0;
}

static int dm_vowel(const dm_state *state, int index)
{
    if (index < 0 || index >= state->length) return 0;
    const uint8_t value = dm_at(state, index);
    return value == 'A' || value == 'E' || value == 'I' || value == 'O' ||
           value == 'U' || value == 'Y';
}

static void dm_append(uint8_t *target, uint8_t *length, const char *fragment)
{
    while (*fragment != '\0' && *length < DM_KEY_LIMIT)
        target[(*length)++] = (uint8_t)*fragment++;
}

static void dm_emit(dm_state *state, const char *main, const char *alternate)
{
    if (alternate == NULL) {
        dm_append(state->primary, &state->primary_length, main);
        dm_append(state->secondary, &state->secondary_length, main);
        return;
    }
    dm_append(state->primary, &state->primary_length, main);
    if (*alternate != '\0') {
        state->alternate_seen = 1;
        if (*alternate != ' ')
            dm_append(state->secondary, &state->secondary_length, alternate);
    } else if (*main != '\0' && *main != ' ') {
        dm_append(state->secondary, &state->secondary_length, main);
    }
}

static int dm_slavo_germanic(const dm_state *state)
{
    for (int index = 0; index < state->length; ++index)
        if (dm_at(state, index) == 'W' || dm_at(state, index) == 'K' ||
            dm_has(state, index, "CZ") || dm_has(state, index, "WITZ")) return 1;
    return 0;
}

static int dm_c(dm_state *state, int index)
{
    if (index > 1 && !dm_vowel(state, index - 2) && dm_has(state, index - 1, "ACH") &&
        dm_at(state, index + 2) != 'I' &&
        (dm_at(state, index + 2) != 'E' || dm_has(state, index - 2, "BACHER") ||
         dm_has(state, index - 2, "MACHER"))) {
        dm_emit(state, "K", NULL); return index + 2;
    }
    if (index == 0 && dm_has(state, index, "CAESAR")) {
        dm_emit(state, "S", NULL); return index + 2;
    }
    if (dm_has(state, index, "CHIA")) {
        dm_emit(state, "K", NULL); return index + 2;
    }
    if (dm_has(state, index, "CH")) {
        if (index > 0 && dm_has(state, index, "CHAE")) {
            dm_emit(state, "K", "X"); return index + 2;
        }
        if (index == 0 &&
            (dm_has(state, index + 1, "HARAC") || dm_has(state, index + 1, "HARIS") ||
             dm_has(state, index + 1, "HOR") || dm_has(state, index + 1, "HYM") ||
             dm_has(state, index + 1, "HIA") || dm_has(state, index + 1, "HEM")) &&
            !dm_has(state, 0, "CHORE")) {
            dm_emit(state, "K", NULL); return index + 2;
        }
        const int hard = dm_has(state, 0, "VAN ") || dm_has(state, 0, "VON ") ||
            dm_has(state, 0, "SCH") || dm_has(state, index - 2, "ORCHES") ||
            dm_has(state, index - 2, "ARCHIT") || dm_has(state, index - 2, "ORCHID") ||
            dm_at(state, index + 2) == 'T' || dm_at(state, index + 2) == 'S' ||
            ((dm_at(state, index - 1) == 'A' || dm_at(state, index - 1) == 'O' ||
              dm_at(state, index - 1) == 'U' || dm_at(state, index - 1) == 'E' || index == 0) &&
             (dm_at(state, index + 2) == 'L' || dm_at(state, index + 2) == 'R' ||
              dm_at(state, index + 2) == 'N' || dm_at(state, index + 2) == 'M' ||
              dm_at(state, index + 2) == 'B' || dm_at(state, index + 2) == 'H' ||
              dm_at(state, index + 2) == 'F' || dm_at(state, index + 2) == 'V' ||
              dm_at(state, index + 2) == 'W' || dm_at(state, index + 2) == ' '));
        if (hard) dm_emit(state, "K", NULL);
        else if (index > 0) {
            if (dm_has(state, 0, "MC")) dm_emit(state, "K", NULL);
            else dm_emit(state, "X", "K");
        } else dm_emit(state, "X", NULL);
        return index + 2;
    }
    if (dm_has(state, index, "CZ") && !dm_has(state, index - 2, "WICZ")) {
        dm_emit(state, "S", "X"); return index + 2;
    }
    if (dm_has(state, index + 1, "CIA")) {
        dm_emit(state, "X", NULL); return index + 3;
    }
    if (dm_has(state, index, "CC") && !(index == 1 && dm_at(state, 0) == 'M')) {
        if ((dm_at(state, index + 2) == 'I' || dm_at(state, index + 2) == 'E' ||
             dm_at(state, index + 2) == 'H') && !dm_has(state, index + 2, "HU")) {
            if ((index == 1 && dm_at(state, index - 1) == 'A') ||
                dm_has(state, index - 1, "UCCEE") || dm_has(state, index - 1, "UCCES"))
                dm_emit(state, "KS", NULL);
            else dm_emit(state, "X", NULL);
            return index + 3;
        }
        dm_emit(state, "K", NULL); return index + 2;
    }
    if (dm_has(state, index, "CK") || dm_has(state, index, "CG") || dm_has(state, index, "CQ")) {
        dm_emit(state, "K", NULL); return index + 2;
    }
    if (dm_has(state, index, "CI") || dm_has(state, index, "CE") || dm_has(state, index, "CY")) {
        if (dm_has(state, index, "CIO") || dm_has(state, index, "CIE") || dm_has(state, index, "CIA"))
            dm_emit(state, "S", "X");
        else dm_emit(state, "S", NULL);
        return index + 2;
    }
    dm_emit(state, "K", NULL);
    if (dm_has(state, index + 1, " C") || dm_has(state, index + 1, " Q") ||
        dm_has(state, index + 1, " G")) return index + 3;
    if ((dm_at(state, index + 1) == 'C' || dm_at(state, index + 1) == 'K' ||
         dm_at(state, index + 1) == 'Q') && !dm_has(state, index + 1, "CE") &&
        !dm_has(state, index + 1, "CI")) return index + 2;
    return index + 1;
}

static int dm_g(dm_state *state, int index, int slavo)
{
    if (dm_at(state, index + 1) == 'H') {
        if (index > 0 && !dm_vowel(state, index - 1)) {
            dm_emit(state, "K", NULL); return index + 2;
        }
        if (index == 0) {
            dm_emit(state, dm_at(state, index + 2) == 'I' ? "J" : "K", NULL);
            return index + 2;
        }
        if ((index > 1 && (dm_at(state, index - 2) == 'B' || dm_at(state, index - 2) == 'H' || dm_at(state, index - 2) == 'D')) ||
            (index > 2 && (dm_at(state, index - 3) == 'B' || dm_at(state, index - 3) == 'H' || dm_at(state, index - 3) == 'D')) ||
            (index > 3 && (dm_at(state, index - 4) == 'B' || dm_at(state, index - 4) == 'H'))) return index + 2;
        if (index > 2 && dm_at(state, index - 1) == 'U' &&
            (dm_at(state, index - 3) == 'C' || dm_at(state, index - 3) == 'G' ||
             dm_at(state, index - 3) == 'L' || dm_at(state, index - 3) == 'R' || dm_at(state, index - 3) == 'T'))
            dm_emit(state, "F", NULL);
        else if (index > 0 && dm_at(state, index - 1) != 'I') dm_emit(state, "K", NULL);
        return index + 2;
    }
    if (dm_at(state, index + 1) == 'N') {
        if (index == 1 && dm_vowel(state, 0) && !slavo) dm_emit(state, "KN", "N");
        else if (!dm_has(state, index + 2, "EY") && dm_at(state, index + 1) != 'Y' && !slavo)
            dm_emit(state, "N", "KN");
        else dm_emit(state, "KN", NULL);
        return index + 2;
    }
    if (dm_has(state, index + 1, "LI") && !slavo) {
        dm_emit(state, "KL", "L"); return index + 2;
    }
    if (index == 0 && (dm_at(state, index + 1) == 'Y' ||
        dm_has(state, index + 1, "ES") || dm_has(state, index + 1, "EP") ||
        dm_has(state, index + 1, "EB") || dm_has(state, index + 1, "EL") ||
        dm_has(state, index + 1, "EY") || dm_has(state, index + 1, "IB") ||
        dm_has(state, index + 1, "IL") || dm_has(state, index + 1, "IN") ||
        dm_has(state, index + 1, "IE") || dm_has(state, index + 1, "EI") ||
        dm_has(state, index + 1, "ER"))) {
        dm_emit(state, "K", "J"); return index + 2;
    }
    if ((dm_has(state, index + 1, "ER") || dm_at(state, index + 1) == 'Y') &&
        !dm_has(state, 0, "DANGER") && !dm_has(state, 0, "RANGER") && !dm_has(state, 0, "MANGER") &&
        dm_at(state, index - 1) != 'E' && dm_at(state, index - 1) != 'I' &&
        !dm_has(state, index - 1, "RGY") && !dm_has(state, index - 1, "OGY")) {
        dm_emit(state, "K", "J"); return index + 2;
    }
    if (dm_at(state, index + 1) == 'E' || dm_at(state, index + 1) == 'I' ||
        dm_at(state, index + 1) == 'Y' || dm_has(state, index - 1, "AGGI") ||
        dm_has(state, index - 1, "OGGI")) {
        if (dm_has(state, 0, "VAN ") || dm_has(state, 0, "VON ") || dm_has(state, 0, "SCH") ||
            dm_has(state, index + 1, "ET")) dm_emit(state, "K", NULL);
        else if (dm_has(state, index + 1, "IER ")) dm_emit(state, "J", NULL);
        else dm_emit(state, "J", "K");
        return index + 2;
    }
    const int next = dm_at(state, index + 1) == 'G' ? index + 2 : index + 1;
    dm_emit(state, "K", NULL);
    return next;
}

static int dm_j(dm_state *state, int index, int slavo)
{
    if (dm_has(state, index, "JOSE") || dm_has(state, 0, "SAN ")) {
        if ((index == 0 && dm_at(state, index + 4) == ' ') || dm_has(state, 0, "SAN "))
            dm_emit(state, "H", NULL);
        else dm_emit(state, "J", "H");
        return index + 1;
    }
    if (index == 0) dm_emit(state, "J", "A");
    else if (dm_vowel(state, index - 1) && !slavo &&
             (dm_at(state, index + 1) == 'A' || dm_at(state, index + 1) == 'O')) dm_emit(state, "J", "H");
    else if (index == state->length - 1) dm_emit(state, "J", " ");
    else if (!(dm_at(state, index + 1) == 'L' || dm_at(state, index + 1) == 'T' ||
               dm_at(state, index + 1) == 'K' || dm_at(state, index + 1) == 'S' ||
               dm_at(state, index + 1) == 'N' || dm_at(state, index + 1) == 'M' ||
               dm_at(state, index + 1) == 'B' || dm_at(state, index + 1) == 'Z') &&
             dm_at(state, index - 1) != 'S' && dm_at(state, index - 1) != 'K' &&
             dm_at(state, index - 1) != 'L') dm_emit(state, "J", NULL);
    return index + (dm_at(state, index + 1) == 'J' ? 2 : 1);
}

static int dm_l(dm_state *state, int index)
{
    if (dm_at(state, index + 1) != 'L') { dm_emit(state, "L", NULL); return index + 1; }
    const int spanish = (index == state->length - 3 &&
        (dm_has(state, index - 1, "ILLO") || dm_has(state, index - 1, "ILLA") || dm_has(state, index - 1, "ALLE"))) ||
        ((dm_has(state, state->length - 3, "AS") || dm_has(state, state->length - 3, "OS") ||
          dm_at(state, state->length - 1) == 'A' || dm_at(state, state->length - 1) == 'O') &&
         dm_has(state, index - 1, "ALLE"));
    if (spanish) dm_emit(state, "L", " ");
    else dm_emit(state, "L", NULL);
    return index + 2;
}

static int dm_s(dm_state *state, int index, int slavo)
{
    if (dm_has(state, index - 1, "ISL") || dm_has(state, index - 1, "YSL")) return index + 1;
    if (index == 0 && dm_has(state, index, "SUGAR")) {
        dm_emit(state, "X", "S"); return index + 1;
    }
    if (dm_has(state, index, "SH")) {
        if (dm_has(state, index + 1, "HEIM") || dm_has(state, index + 1, "HOEK") ||
            dm_has(state, index + 1, "HOLM") || dm_has(state, index + 1, "HOLZ")) dm_emit(state, "S", NULL);
        else dm_emit(state, "X", NULL);
        return index + 2;
    }
    if (dm_has(state, index, "SIO") || dm_has(state, index, "SIA") || dm_has(state, index, "SIAN")) {
        if (!slavo) dm_emit(state, "S", "X"); else dm_emit(state, "S", NULL);
        return index + 3;
    }
    if ((index == 0 && (dm_at(state, index + 1) == 'M' || dm_at(state, index + 1) == 'N' ||
                        dm_at(state, index + 1) == 'L' || dm_at(state, index + 1) == 'W')) ||
        dm_at(state, index + 1) == 'Z') {
        dm_emit(state, "S", "X");
        return index + (dm_at(state, index + 1) == 'Z' ? 2 : 1);
    }
    if (dm_has(state, index, "SC")) {
        if (dm_at(state, index + 2) == 'H') {
            if (dm_has(state, index + 3, "OO") || dm_has(state, index + 3, "ER") ||
                dm_has(state, index + 3, "EN") || dm_has(state, index + 3, "UY") ||
                dm_has(state, index + 3, "ED") || dm_has(state, index + 3, "EM")) {
                if (dm_has(state, index + 3, "ER") || dm_has(state, index + 3, "EN")) dm_emit(state, "X", "SK");
                else dm_emit(state, "SK", NULL);
            } else if (index == 0 && !dm_vowel(state, 3) && dm_at(state, 3) != 'W') dm_emit(state, "X", "S");
            else dm_emit(state, "X", NULL);
            return index + 3;
        }
        if (dm_at(state, index + 2) == 'I' || dm_at(state, index + 2) == 'E' || dm_at(state, index + 2) == 'Y')
            dm_emit(state, "S", NULL);
        else dm_emit(state, "SK", NULL);
        return index + 3;
    }
    if (index == state->length - 1 && (dm_has(state, index - 2, "AI") || dm_has(state, index - 2, "OI")))
        dm_emit(state, "", "S");
    else dm_emit(state, "S", NULL);
    return index + ((dm_at(state, index + 1) == 'S' || dm_at(state, index + 1) == 'Z') ? 2 : 1);
}

static int dm_t(dm_state *state, int index)
{
    if (dm_has(state, index, "TION")) { dm_emit(state, "X", NULL); return index + 3; }
    if (dm_has(state, index, "TIA") || dm_has(state, index, "TCH")) { dm_emit(state, "X", NULL); return index + 3; }
    if (dm_has(state, index, "TH") || dm_has(state, index, "TTH")) {
        if (dm_has(state, index + 2, "OM") || dm_has(state, index + 2, "AM") ||
            dm_has(state, 0, "VAN ") || dm_has(state, 0, "VON ") || dm_has(state, 0, "SCH"))
            dm_emit(state, "T", NULL);
        else dm_emit(state, "0", "T");
        return index + 2;
    }
    dm_emit(state, "T", NULL);
    return index + ((dm_at(state, index + 1) == 'T' || dm_at(state, index + 1) == 'D') ? 2 : 1);
}

static int dm_w(dm_state *state, int index)
{
    if (dm_has(state, index, "WR")) { dm_emit(state, "R", NULL); return index + 2; }
    if (index == 0 && (dm_vowel(state, index + 1) || dm_has(state, index, "WH"))) {
        if (dm_vowel(state, index + 1)) dm_emit(state, "A", "F");
        else dm_emit(state, "A", NULL);
    }
    if ((index == state->length - 1 && dm_vowel(state, index - 1)) ||
        dm_has(state, index - 1, "EWSKI") || dm_has(state, index - 1, "EWSKY") ||
        dm_has(state, index - 1, "OWSKI") || dm_has(state, index - 1, "OWSKY") || dm_has(state, 0, "SCH")) {
        dm_emit(state, "", "F"); return index + 1;
    }
    if (dm_has(state, index, "WICZ") || dm_has(state, index, "WITZ")) {
        dm_emit(state, "TS", "FX"); return index + 4;
    }
    return index + 1;
}

static int dm_x(dm_state *state, int index)
{
    const int french_end = index == state->length - 1 &&
        (dm_has(state, index - 3, "IAU") || dm_has(state, index - 3, "EAU") ||
         dm_has(state, index - 2, "AU") || dm_has(state, index - 2, "OU"));
    if (!french_end) dm_emit(state, "KS", NULL);
    return index + ((dm_at(state, index + 1) == 'C' || dm_at(state, index + 1) == 'X') ? 2 : 1);
}

static int dm_z(dm_state *state, int index, int slavo)
{
    if (dm_at(state, index + 1) == 'H') { dm_emit(state, "J", NULL); return index + 2; }
    if (dm_has(state, index + 1, "ZO") || dm_has(state, index + 1, "ZI") ||
        dm_has(state, index + 1, "ZA") ||
        (slavo && index > 0 && dm_at(state, index - 1) != 'T')) dm_emit(state, "S", "TS");
    else dm_emit(state, "S", NULL);
    return index + (dm_at(state, index + 1) == 'Z' ? 2 : 1);
}

static uint8_t dm_upper(uint8_t value)
{
    if (value >= 'a' && value <= 'z') return (uint8_t)(value - ('a' - 'A'));
    if (value == 0xE7) return 0xC7;
    if (value == 0xF1) return 0xD1;
    return value;
}

int64_t double_metaphone(const int64_t *values, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > DM_MAX_INPUT + 1) return -1;
    if (values[0] < 0 || values[0] > DM_TEXT_LIMIT) return -1;
    const size_t count = (size_t)values[0];
    if (length != count + 1) return -1;

    dm_state state = {0};
    memset(state.text, ' ', sizeof(state.text));
    state.length = (uint8_t)count;
    for (size_t index = 0; index < count; ++index) {
        const int64_t raw = values[index + 1];
        if (!((raw >= 'A' && raw <= 'Z') || (raw >= 'a' && raw <= 'z') || raw == ' ' ||
              raw == 0xC7 || raw == 0xE7 || raw == 0xD1 || raw == 0xF1)) return -1;
        state.text[index] = dm_upper((uint8_t)raw);
    }
    const int slavo = dm_slavo_germanic(&state);
    int index = 0;
    if (dm_has(&state, 0, "GN") || dm_has(&state, 0, "KN") || dm_has(&state, 0, "PN") ||
        dm_has(&state, 0, "WR") || dm_has(&state, 0, "PS")) index = 1;
    if (dm_at(&state, 0) == 'X') { dm_emit(&state, "S", NULL); index = 1; }

    while (index < state.length &&
           (state.primary_length < DM_KEY_LIMIT || state.secondary_length < DM_KEY_LIMIT)) {
        switch (dm_at(&state, index)) {
        case 'A': case 'E': case 'I': case 'O': case 'U': case 'Y':
            if (index == 0) dm_emit(&state, "A", NULL);
            ++index; break;
        case 'B':
            dm_emit(&state, "P", NULL);
            index += dm_at(&state, index + 1) == 'B' ? 2 : 1; break;
        case 0xC7:
            dm_emit(&state, "S", NULL); ++index; break;
        case 'C': index = dm_c(&state, index); break;
        case 'D':
            if (dm_has(&state, index, "DG")) {
                if (dm_at(&state, index + 2) == 'I' || dm_at(&state, index + 2) == 'E' || dm_at(&state, index + 2) == 'Y') {
                    dm_emit(&state, "J", NULL); index += 3;
                } else { dm_emit(&state, "TK", NULL); index += 2; }
            } else if (dm_has(&state, index, "DT") || dm_has(&state, index, "DD")) {
                dm_emit(&state, "T", NULL); index += 2;
            } else { dm_emit(&state, "T", NULL); ++index; }
            break;
        case 'F':
            dm_emit(&state, "F", NULL); index += dm_at(&state, index + 1) == 'F' ? 2 : 1; break;
        case 'G': index = dm_g(&state, index, slavo); break;
        case 'H':
            if ((index == 0 || dm_vowel(&state, index - 1)) && dm_vowel(&state, index + 1)) {
                dm_emit(&state, "H", NULL); index += 2;
            } else ++index;
            break;
        case 'J': index = dm_j(&state, index, slavo); break;
        case 'K':
            dm_emit(&state, "K", NULL); index += dm_at(&state, index + 1) == 'K' ? 2 : 1; break;
        case 'L': index = dm_l(&state, index); break;
        case 'M':
            if ((dm_has(&state, index - 1, "UMB") &&
                 (index + 1 == state.length - 1 || dm_has(&state, index + 2, "ER"))) ||
                dm_at(&state, index + 1) == 'M') index += 2;
            else ++index;
            dm_emit(&state, "M", NULL); break;
        case 'N':
            dm_emit(&state, "N", NULL); index += dm_at(&state, index + 1) == 'N' ? 2 : 1; break;
        case 0xD1:
            dm_emit(&state, "N", NULL); ++index; break;
        case 'P':
            if (dm_at(&state, index + 1) == 'H') { dm_emit(&state, "F", NULL); index += 2; }
            else { dm_emit(&state, "P", NULL); index += (dm_at(&state, index + 1) == 'P' || dm_at(&state, index + 1) == 'B') ? 2 : 1; }
            break;
        case 'Q':
            dm_emit(&state, "K", NULL); index += dm_at(&state, index + 1) == 'Q' ? 2 : 1; break;
        case 'R':
            if (index == state.length - 1 && !slavo && dm_has(&state, index - 2, "IE") &&
                !dm_has(&state, index - 4, "ME") && !dm_has(&state, index - 4, "MA")) dm_emit(&state, "", "R");
            else dm_emit(&state, "R", NULL);
            index += dm_at(&state, index + 1) == 'R' ? 2 : 1; break;
        case 'S': index = dm_s(&state, index, slavo); break;
        case 'T': index = dm_t(&state, index); break;
        case 'V':
            dm_emit(&state, "F", NULL); index += dm_at(&state, index + 1) == 'V' ? 2 : 1; break;
        case 'W': index = dm_w(&state, index); break;
        case 'X': index = dm_x(&state, index); break;
        case 'Z': index = dm_z(&state, index, slavo); break;
        default: ++index; break;
        }
    }

    uint8_t secondary_length = state.alternate_seen ? state.secondary_length : 0;
    if (secondary_length == state.primary_length &&
        memcmp(state.primary, state.secondary, state.primary_length) == 0) secondary_length = 0;
    const size_t required = 2 + state.primary_length + secondary_length;
    if (output == NULL || output_capacity < required) return -2;
    output[0] = state.primary_length;
    output[1] = secondary_length;
    memcpy(output + 2, state.primary, state.primary_length);
    if (secondary_length != 0)
        memcpy(output + 2 + state.primary_length, state.secondary, secondary_length);
    return (int64_t)required;
}
