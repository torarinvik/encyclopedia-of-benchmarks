module versabench_bmm;

// Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source.

const usz MAX_SIZE = 128;
const usz SOURCE_SIZE = 1024;
const usz MAX_CELLS = MAX_SIZE * MAX_SIZE;
const usz MAX_OUTPUT_BYTES = 29;

fn uint next_random(uint* state) {
    *state = ((ulong)*state * 1664525 + 1013904223).uint();
    return (*state >> 16) & 0x7fff;
}

fn usz append_unsigned(uint value_input, char* staged, usz used) {
    uint value = value_input;
    char[10] reverse;
    usz count = 0;
    do {
        reverse[count++] = (char)(48 + value % 10);
        value /= 10;
    } while (value != 0);
    while (count != 0) staged[used++] = reverse[--count];
    return used;
}

fn long versabench_bmm(long* input, usz length, char* output, usz output_capacity)
    @export("versabench_bmm") {
    if (input == null || length != 2) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_SIZE || input[1] < 1 ||
        input[1] > input[0] || input[0] % input[1] != 0) return -1;
    usz size = input[0].usz();
    usz block = input[1].usz();

    float[MAX_CELLS] a = {};
    float[MAX_CELLS] b = {};
    float[MAX_CELLS] c = {};
    uint seed = 1;
    for (usz i = 0; i < size; i++) {
        for (usz j = 0; j < SOURCE_SIZE; j++) {
            uint random_a = next_random(&seed);
            uint random_b = next_random(&seed);
            if (j < size) {
                uint shift_a = (((j & 31) + 32 - (i & 31)) & 31).uint();
                uint shift_b = ((i + j) & 31).uint();
                a[i * size + j] = ((random_a >> shift_a) & 15).float();
                b[i * size + j] = ((random_b << shift_b) & 15).float();
            }
        }
    }

    for (usz outer_i = 0; outer_i < size; outer_i += block) {
        for (usz outer_j = 0; outer_j < size; outer_j += block) {
            for (usz outer_k = 0; outer_k < size; outer_k += block) {
                for (usz i = outer_i; i < outer_i + block; i++) {
                    for (usz j = outer_j; j < outer_j + block; j++) {
                        usz cell = i * size + j;
                        for (usz k = outer_k; k < outer_k + block; k++)
                            c[cell] += a[i * size + k] * b[k * size + j];
                    }
                }
            }
        }
    }

    float total = 0;
    for (usz outer_i = 0; outer_i < size; outer_i += block) {
        for (usz outer_j = 0; outer_j < size; outer_j += block) {
            float subtotal = 0;
            for (usz i = outer_i; i < outer_i + block; i++)
                for (usz j = outer_j; j < outer_j + block; j++)
                    subtotal += c[i * size + j];
            total += subtotal;
        }
    }

    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    const char* prefix = "final sum = ";
    for (usz i = 0; i < 12; i++) staged[used++] = prefix[i];
    used = append_unsigned(total.uint(), &staged[0], used);
    const char* suffix = ".000000\n";
    for (usz i = 0; i < 8; i++) staged[used++] = suffix[i];
    if (output == null || output_capacity < used) return -2;
    for (usz i = 0; i < used; i++) output[i] = staged[i];
    return used.long();
}
