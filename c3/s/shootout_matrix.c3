module shootout_matrix;

const int MATRIX_SIZE = 10;
const int CELL_COUNT = MATRIX_SIZE * MATRIX_SIZE;
const long MAX_ITERATIONS = 4096;
const usz MAX_OUTPUT_BYTES = 23;

fn void append_integer(int value, char* buffer, usz* used) {
    char[10] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[(*used)++] = reversed[--count];
}

fn long shootout_matrix(long iteration_count, char* output, usz output_capacity)
    @export("shootout_matrix")
{
    if (iteration_count < 0 || iteration_count > MAX_ITERATIONS) return -1;

    int[CELL_COUNT] left;
    int[CELL_COUNT] right;
    int[CELL_COUNT] product;
    for (int index = 0; index < CELL_COUNT; index++) {
        left[index] = index + 1;
        right[index] = index + 1;
        product[index] = index + 1;
    }

    for (long iteration = 0; iteration < iteration_count; iteration++) {
        for (int row = 0; row < MATRIX_SIZE; row++) {
            for (int column = 0; column < MATRIX_SIZE; column++) {
                int value = 0;
                for (int inner = 0; inner < MATRIX_SIZE; inner++)
                    value += left[row * MATRIX_SIZE + inner] * right[inner * MATRIX_SIZE + column];
                product[row * MATRIX_SIZE + column] = value;
            }
        }
    }

    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    append_integer(product[0], staged, &used);
    staged[used++] = ' ';
    append_integer(product[23], staged, &used);
    staged[used++] = ' ';
    append_integer(product[32], staged, &used);
    staged[used++] = ' ';
    append_integer(product[44], staged, &used);
    staged[used++] = '\n';

    if (output == null || output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}
