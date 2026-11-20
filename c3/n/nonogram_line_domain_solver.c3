module nonogram_line_domain_solver;

const usz LINES = 16;
const usz SIDE = 8;
const usz WORDS = 4;

struct Domains { ulong[LINES][WORDS] words; }

fn bool matches(uint mask, usz length, long* clue, usz count) {
    usz found = 0, run = 0;
    for (usz bit = 0; bit < length; bit++) {
        if (((mask >> bit) & 1) != 0) run++;
        else if (run != 0) {
            if (found >= count || clue[found] != (long)run) return false;
            found++; run = 0;
        }
    }
    if (run != 0) {
        if (found >= count || clue[found] != (long)run) return false;
        found++;
    }
    return found == count;
}
fn bool has(Domains* domains, usz line, uint mask) {
    return (domains.words[line][mask >> 6] & (1ul << (mask & 63))) != 0;
}
fn void add(Domains* domains, usz line, uint mask) {
    domains.words[line][mask >> 6] |= 1ul << (mask & 63);
}
fn usz count(Domains* domains, usz line, usz length) {
    usz total = 0;
    for (uint mask = 0; mask < (1u << length); mask++) if (has(domains, line, mask)) total++;
    return total;
}
fn bool filter(Domains* domains, usz line, usz length, usz pos, bool allow_zero, bool allow_one) {
    bool changed = false;
    for (uint mask = 0; mask < (1u << length); mask++) {
        if (!has(domains, line, mask)) continue;
        bool one = ((mask >> pos) & 1) != 0;
        if (one ? allow_one : allow_zero) continue;
        domains.words[line][mask >> 6] &= ~(1ul << (mask & 63));
        changed = true;
    }
    return changed;
}
fn bool support(Domains* domains, usz line, usz length, usz pos, bool* zero, bool* one) {
    *zero = false; *one = false;
    for (uint mask = 0; mask < (1u << length); mask++) {
        if (!has(domains, line, mask)) continue;
        if (((mask >> pos) & 1) != 0) *one = true; else *zero = true;
    }
    return *zero || *one;
}
fn bool propagate(Domains* domains, usz height, usz width) {
    bool changed;
    do {
        changed = false;
        for (usz row = 0; row < height; row++) for (usz col = 0; col < width; col++) {
            bool rz, ro, cz, co;
            if (!support(domains, row, width, col, &rz, &ro) ||
                !support(domains, height + col, height, row, &cz, &co)) return false;
            changed |= filter(domains, row, width, col, cz, co);
            changed |= filter(domains, height + col, height, row, rz, ro);
            if (count(domains, row, width) == 0 || count(domains, height + col, height) == 0) return false;
        }
    } while (changed);
    return true;
}
fn bool search(Domains* domains, usz height, usz width) {
    if (!propagate(domains, height, width)) return false;
    usz branch = height;
    for (usz row = 0; row < height; row++) if (count(domains, row, width) > 1) { branch = row; break; }
    if (branch == height) return true;
    for (uint mask = 0; mask < (1u << width); mask++) {
        if (!has(domains, branch, mask)) continue;
        Domains trial = *domains;
        for (usz word = 0; word < WORDS; word++) trial.words[branch][word] = 0;
        add(&trial, branch, mask);
        if (search(&trial, height, width)) { *domains = trial; return true; }
    }
    return false;
}
fn bool parse(long* input, usz length, usz* height, usz* width, long* clues, usz* counts) {
    if (input == null || length < 2 || input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8) return false;
    *height = (usz)input[0]; *width = (usz)input[1];
    if (length != 2 + 5 * *height + 5 * *width) return false;
    for (usz i = 0; i < LINES * SIDE; i++) clues[i] = 0;
    for (usz i = 0; i < LINES; i++) counts[i] = 0;
    usz offset = 2;
    for (usz group = 0; group < 2; group++) {
        usz lines = group == 0 ? *height : *width;
        usz line_length = group == 0 ? *width : *height;
        for (usz line = 0; line < lines; line++) {
            usz index = group == 0 ? line : *height + line;
            long raw_count = input[offset++];
            if (raw_count < 0 || raw_count > 4) return false;
            counts[index] = (usz)raw_count;
            long needed = raw_count == 0 ? 0 : raw_count - 1;
            for (usz run = 0; run < 4; run++) {
                long value = input[offset++];
                if (run < counts[index]) {
                    if (value <= 0 || value > (long)line_length) return false;
                    clues[index * SIDE + run] = value; needed += value;
                } else if (value != 0) return false;
            }
            if (needed > (long)line_length) return false;
        }
    }
    long row_total = 0, col_total = 0;
    for (usz row = 0; row < *height; row++) for (usz k = 0; k < counts[row]; k++) row_total += clues[row * SIDE + k];
    for (usz col = 0; col < *width; col++) for (usz k = 0; k < counts[*height + col]; k++) col_total += clues[(*height + col) * SIDE + k];
    return row_total == col_total;
}
fn bool initialize(Domains* domains, usz height, usz width, long* clues, usz* counts) {
    for (usz row = 0; row < height; row++) {
        for (uint mask = 0; mask < (1u << width); mask++)
            if (matches(mask, width, &clues[row * SIDE], counts[row])) add(domains, row, mask);
        if (count(domains, row, width) == 0) return false;
    }
    for (usz col = 0; col < width; col++) {
        usz line = height + col;
        for (uint mask = 0; mask < (1u << height); mask++)
            if (matches(mask, height, &clues[line * SIDE], counts[line])) add(domains, line, mask);
        if (count(domains, line, height) == 0) return false;
    }
    return true;
}

fn long nonogram_line_domain_solver(long* input, usz length, char* output, usz capacity)
    @export("nonogram_line_domain_solver") {
    usz height = 0, width = 0;
    long[LINES * SIDE] clues = zeroed;
    usz[LINES] counts = zeroed;
    if (!parse(input, length, &height, &width, &clues[0], &counts[0])) return -1;
    Domains domains = {};
    if (!initialize(&domains, height, width, &clues[0], &counts[0]) || !search(&domains, height, width)) return -1;
    usz required = height * width;
    if (output == null || capacity < required) return -2;
    for (usz row = 0; row < height; row++) {
        uint mask = 0;
        while (mask < (1u << width) && !has(&domains, row, mask)) mask++;
        for (usz col = 0; col < width; col++) output[row * width + col] = (char)((mask >> col) & 1);
    }
    return (long)required;
}
