module mcgill_misr;

const long MIN_EXPERIMENTS = 1;
const long MAX_EXPERIMENTS = 1000;
const usz MAX_OUTPUT_BYTES = 123;
const ulong MASK_48 = 0xFFFFFFFFFFFFul;
const ulong MASK_24 = 0xFFFFFFul;

fn uint next_lrand48(ulong* state) {
    ulong low = *state & MASK_24;
    ulong high = *state >> 24;
    ulong high_product = (high * 0xECE66Dul) & MASK_24;
    *state = (low * 0x5DEECE66Dul + (high_product << 24) + 0xBul) & MASK_48;
    return (uint)(*state >> 17);
}

fn bool different_experiment(ulong* random_state, char* free_state) {
    char[10] faulty_state;
    for (usz cell = 0; cell < 10; cell++) faulty_state[cell] = free_state[cell];
    for (int vector = 0; vector < 10; vector++) {
        char saved_free = free_state[0];
        char saved_faulty = faulty_state[0];
        uint random_word = next_lrand48(random_state);
        for (usz cell = 0; cell < 9; cell++) {
            free_state[cell] = (char)(((uint)free_state[cell + 1] + random_word) & 1u);
            uint random_probability = next_lrand48(random_state);
            if (random_probability % 1000u < 250u) random_word ^= 1u;
            faulty_state[cell] = (char)(((uint)faulty_state[cell + 1] + random_word) & 1u);
            random_word >>= 1;
        }
        random_word = next_lrand48(random_state);
        free_state[9] = (char)(((uint)saved_free + random_word) & 1u);
        uint random_probability = next_lrand48(random_state);
        if (random_probability % 10000u < 2500u) random_word ^= 1u;
        faulty_state[9] = (char)(((uint)saved_faulty + random_word) & 1u);
    }
    for (usz cell = 0; cell < 10; cell++)
        if (free_state[cell] != faulty_state[cell]) return true;
    return false;
}

fn void append_text(char* buffer, usz* used, const char* text) {
    while (*text != '\0') buffer[(*used)++] = *text++;
}

fn void append_unsigned(char* buffer, usz* used, ulong value) {
    char[24] reverse;
    usz count = 0;
    do {
        reverse[count++] = (char)('0' + value % 10ul);
        value /= 10ul;
    } while (value != 0);
    while (count > 0) buffer[(*used)++] = reverse[--count];
}

fn void append_probability(char* buffer, usz* used, ulong same_count, ulong experiments) {
    ulong mantissa = 0;
    int exponent = 0;
    if (same_count != 0) {
        ulong scale = 1;
        while (same_count * scale < experiments) { scale *= 10; exponent--; }
        ulong numerator = same_count * scale * 100000000;
        mantissa = numerator / experiments;
        ulong remainder = numerator % experiments;
        if (2 * remainder > experiments || (2 * remainder == experiments && (mantissa & 1ul) != 0))
            mantissa++;
        if (mantissa == 1000000000) { mantissa = 100000000; exponent++; }
    }
    ulong whole = mantissa / 100000000;
    ulong fraction = mantissa % 100000000;
    buffer[(*used)++] = (char)('0' + whole);
    buffer[(*used)++] = '.';
    ulong place = 10000000;
    for (int digit = 0; digit < 8; digit++) {
        buffer[(*used)++] = (char)('0' + fraction / place);
        fraction %= place;
        place /= 10;
    }
    buffer[(*used)++] = 'e';
    uint absolute_exponent = (uint)(exponent < 0 ? -exponent : exponent);
    buffer[(*used)++] = exponent < 0 ? '-' : '+';
    buffer[(*used)++] = (char)('0' + absolute_exponent / 10);
    buffer[(*used)++] = (char)('0' + absolute_exponent % 10);
}

fn long mcgill_misr(long experiments, char* output, usz output_capacity)
    @export("mcgill_misr") {
    if (experiments < MIN_EXPERIMENTS || experiments > MAX_EXPERIMENTS) return -1;
    if (output == null) return -2;
    ulong random_state = 1;
    char[10] free_state;
    for (usz cell = 0; cell < 10; cell++) free_state[cell] = cell == 0 ? 0 : 1;
    ulong different_count = 0;
    for (long experiment = 0; experiment < experiments; experiment++)
        if (different_experiment(&random_state, &free_state[0])) different_count++;
    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    append_text(&staged[0], &used, "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ");
    append_text(&staged[0], &used, "10 10 2.500e-01 ");
    append_unsigned(&staged[0], &used, (ulong)experiments);
    append_text(&staged[0], &used, " 1000000000 1 0 0 ");
    append_probability(&staged[0], &used, (ulong)experiments - different_count, (ulong)experiments);
    staged[used++] = '\n';
    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}
