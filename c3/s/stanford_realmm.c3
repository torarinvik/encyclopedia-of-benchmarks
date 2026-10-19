module stanford_realmm;

const usz ROWSIZE = 40;
const usz CELL_COUNT = ROWSIZE * ROWSIZE;
const long MAX_PASSES = 10;
const usz MAX_OUTPUT_BYTES = 140;

fn ulong rounded_micro_units(ulong bits) {
    ulong exponent = (bits >> 52) & 0x7fful;
    ulong significand = bits & ((1ul << 52) - 1ul);
    if (exponent == 0) return 0;
    significand |= 1ul << 52;
    ulong shift = 1075ul - exponent;
    if (shift >= 74ul) return 0;
    ulong low_product = (significand & 0xfffffffful) * 1000000ul;
    ulong high_product = (significand >> 32) * 1000000ul;
    ulong middle = (low_product >> 32) + (high_product & 0xfffffffful);
    ulong limb0 = low_product & 0xfffffffful;
    ulong limb1 = middle & 0xfffffffful;
    ulong limb2 = (high_product >> 32) + (middle >> 32);
    ulong quotient, half_bit;
    bool lower_nonzero;
    if (shift < 64ul) {
        usz part = (usz)(shift - 32ul);
        quotient = (limb1 >> part) | (limb2 << (32 - part));
        half_bit = (limb1 >> (part - 1)) & 1ul;
        lower_nonzero = limb0 != 0 || (limb1 & ((1ul << (part - 1)) - 1ul)) != 0;
    } else if (shift == 64ul) {
        quotient = limb2;
        half_bit = limb1 >> 31;
        lower_nonzero = limb0 != 0 || (limb1 & 0x7ffffffful) != 0;
    } else {
        usz part = (usz)(shift - 64ul);
        quotient = limb2 >> part;
        half_bit = (limb2 >> (part - 1)) & 1ul;
        lower_nonzero = limb0 != 0 || limb1 != 0 || (limb2 & ((1ul << (part - 1)) - 1ul)) != 0;
    }
    if (half_bit != 0 && (lower_nonzero || (quotient & 1ul) != 0)) quotient++;
    return quotient;
}

fn void append_integer(ulong value, char* buffer, usz* used) {
    char[20] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[(*used)++] = reversed[--count];
}

fn void append_fixed(double value, char* buffer, usz* used) {
    ulong bits = @bitcast(ulong, value);
    if ((bits >> 63) != 0) buffer[(*used)++] = '-';
    ulong scaled = rounded_micro_units(bits & ((1ul << 63) - 1ul));
    append_integer(scaled / 1000000ul, buffer, used);
    buffer[(*used)++] = '.';
    ulong fraction = scaled % 1000000ul;
    ulong place = 100000ul;
    while (place > 0) {
        buffer[(*used)++] = (char)('0' + fraction / place);
        fraction %= place;
        place /= 10;
    }
}

fn long stanford_realmm(long pass_count, char* output, usz output_capacity)
    @export("stanford_realmm")
{
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;
    if (output == null) return -2;

    double[CELL_COUNT] a;
    double[CELL_COUNT] b;
    double[CELL_COUNT] product;
    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    for (long pass = 0; pass < pass_count; pass++) {
        long seed = 74755;
        for (usz index = 0; index < CELL_COUNT; index++) {
            seed = (seed * 1309 + 13849) & 65535;
            long temp = seed;
            long residue = temp - (temp / 120) * 120 - 60;
            a[index] = (double)residue / 3.0;
        }
        for (usz index = 0; index < CELL_COUNT; index++) {
            seed = (seed * 1309 + 13849) & 65535;
            long temp = seed;
            long residue = temp - (temp / 120) * 120 - 60;
            b[index] = (double)residue / 3.0;
        }

        for (usz row = 0; row < ROWSIZE; row++) {
            for (usz column = 0; column < ROWSIZE; column++) {
                double sum = 0.0;
                for (usz inner = 0; inner < ROWSIZE; inner++)
                    sum = sum + a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                product[row * ROWSIZE + column] = sum;
            }
        }
        append_fixed(product[(usz)pass * ROWSIZE + (usz)pass], staged, &used);
        staged[used++] = '\n';
    }

    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}
