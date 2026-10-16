module floyd_triangle;

const long MAX_ROWS = 90;

fn long floyd_triangle(long rows, char* output, usz output_capacity)
        @export("floyd_triangle") {
    if (rows < 0 || rows > MAX_ROWS) return -1;
    ulong count = (ulong)rows * ((ulong)rows + 1ul) / 2ul;
    usz output_length = (usz)(count * 2ul);
    if (output_capacity < output_length || (output_length != 0 && output == null)) return -2;

    usz index = 0;
    long number = 1;
    for (long row = 1; row <= rows; row++) {
        for (long column = 0; column < row; column++) {
            output[index * 2] = (char)(number & 255);
            output[index * 2 + 1] = (char)((number >> 8) & 255);
            number++;
            index++;
        }
    }
    return (long)output_length;
}
