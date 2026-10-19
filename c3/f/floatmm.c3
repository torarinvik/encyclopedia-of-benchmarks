module floatmm;

const usz SIDE = 40;
const usz MAX_PASSES = 40;
const usz MAX_OUTPUT_BYTES = 14 * MAX_PASSES;

fn float rounded_add(float left, float right) @noinline { return left + right; }
fn float rounded_mul(float left, float right) @noinline { return left * right; }
fn float rounded_div(float left, float right) @noinline { return left / right; }

fn uint next_random(uint* seed) {
    *seed = (*seed * 1309u + 13849u) & 65535u;
    return *seed;
}

fn float compute_diagonal_cell(usz selected) {
    float[SIDE][SIDE] left = {};
    float[SIDE][SIDE] right = {};
    float[SIDE][SIDE] result = {};
    uint seed = 74755u;
    for (usz row = 0; row < SIDE; row++) {
        for (usz column = 0; column < SIDE; column++) {
            uint temp = next_random(&seed);
            int remainder = (int)(temp - (temp / 120u) * 120u);
            left[row][column] = rounded_div((float)(remainder - 60), 3.0f);
        }
    }
    for (usz row = 0; row < SIDE; row++) {
        for (usz column = 0; column < SIDE; column++) {
            uint temp = next_random(&seed);
            int remainder = (int)(temp - (temp / 120u) * 120u);
            right[row][column] = rounded_div((float)(remainder - 60), 3.0f);
        }
    }
    for (usz row = 0; row < SIDE; row++) {
        for (usz column = 0; column < SIDE; column++) {
            float total = 0.0f;
            for (usz inner = 0; inner < SIDE; inner++) {
                float product = rounded_mul(left[row][inner], right[inner][column]);
                total = rounded_add(total, product);
            }
            result[row][column] = total;
        }
    }
    return result[selected][selected];
}

fn usz write_unsigned(ulong value, char* output, usz offset) {
    char[24] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)(48 + value % 10ul);
        value /= 10ul;
    } while (value != 0);
    for (usz index = 0; index < count; index++)
        output[offset + index] = reversed[count - index - 1];
    return count;
}

fn usz write_fixed_six(float value, char* output, usz offset) {
    uint bits = @bitcast(uint, value);
    uint exponent_bits = (bits >> 23) & 255u;
    uint fraction_bits = bits & 0x7fffffu;
    ulong significand = exponent_bits == 0
        ? (ulong)fraction_bits
        : (ulong)((1u << 23) | fraction_bits);
    int shift = exponent_bits == 0 ? -149 : (int)exponent_bits - 150;
    ulong numerator = significand * 1000000ul;
    ulong micros;
    if (shift >= 0) {
        micros = numerator << (uint)shift;
    } else {
        uint denominator_shift = (uint)(-shift);
        if (denominator_shift >= 64) {
            micros = 0;
        } else {
            micros = numerator >> denominator_shift;
            ulong remainder = numerator & ((1ul << denominator_shift) - 1ul);
            ulong halfway = 1ul << (denominator_shift - 1u);
            if (remainder > halfway || (remainder == halfway && (micros & 1ul) != 0))
                micros++;
        }
    }
    usz position = offset;
    if ((bits >> 31) != 0) output[position++] = '-';
    position += write_unsigned(micros / 1000000ul, output, position);
    output[position++] = '.';
    uint fractional = (uint)(micros % 1000000ul);
    uint place = 100000u;
    while (place > 0) {
        output[position++] = (char)(48u + (fractional / place) % 10u);
        place /= 10u;
    }
    output[position++] = '\n';
    return position - offset;
}

long floatmm(long passes, char* output, usz output_capacity) @export("floatmm") {
    if (passes < 0 || passes > (long)MAX_PASSES) return -1;
    if (passes == 0) return 0;
    if (output == null) return -2;
    char[MAX_OUTPUT_BYTES] formatted = {};
    usz required = 0;
    for (long run = 0; run < passes; run++) {
        float diagonal = compute_diagonal_cell((usz)run);
        required += write_fixed_six(diagonal, formatted, required);
    }
    if (output_capacity < required) return -2;
    for (usz index = 0; index < required; index++) output[index] = formatted[index];
    return (long)required;
}
