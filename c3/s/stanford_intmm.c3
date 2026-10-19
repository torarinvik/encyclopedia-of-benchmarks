module stanford_intmm;

const usz ROWSIZE = 40;
const usz CELL_COUNT = ROWSIZE * ROWSIZE;
const long MAX_PASSES = 10;

fn usz decimal_width(int value) {
    long magnitude = value;
    if (magnitude < 0) magnitude = -magnitude;
    usz width = value < 0 ? 1 : 0;
    do { width++; magnitude /= 10; } while (magnitude != 0);
    return width;
}

fn usz write_decimal(int value, char* output, usz position) {
    long magnitude = value;
    if (magnitude < 0) {
        output[position++] = '-';
        magnitude = -magnitude;
    }
    char[10] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)(48 + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

fn long stanford_intmm(long pass_count, char* output, usz output_capacity)
    @export("stanford_intmm")
{
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;

    int[CELL_COUNT] a;
    int[CELL_COUNT] b;
    int[CELL_COUNT] product;
    int[MAX_PASSES] diagonal;
    for (long pass = 0; pass < pass_count; pass++) {
        long seed = 74755;
        for (usz index = 0; index < CELL_COUNT; index++) {
            seed = (seed * 1309 + 13849) & 65535;
            a[index] = (int)(seed % 120) - 60;
        }
        for (usz index = 0; index < CELL_COUNT; index++) {
            seed = (seed * 1309 + 13849) & 65535;
            b[index] = (int)(seed % 120) - 60;
        }

        for (usz row = 0; row < ROWSIZE; row++) {
            for (usz column = 0; column < ROWSIZE; column++) {
                int sum = 0;
                for (usz inner = 0; inner < ROWSIZE; inner++)
                    sum += a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                product[row * ROWSIZE + column] = sum;
            }
        }
        diagonal[(usz)pass] = product[(usz)pass * ROWSIZE + (usz)pass];
    }

    usz required = 0;
    for (long pass = 0; pass < pass_count; pass++)
        required += decimal_width(diagonal[(usz)pass]) + 1;
    if (output == null || output_capacity < required) return -2;

    usz position = 0;
    for (long pass = 0; pass < pass_count; pass++) {
        position = write_decimal(diagonal[(usz)pass], output, position);
        output[position++] = '\n';
    }
    return (long)position;
}
