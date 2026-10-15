module format_phone_number;

fn long format_phone_number(long* values, usz length, char* output, usz output_capacity)
    @export("format_phone_number")
{
    if (values == null || length != 10) return -1;
    for (usz i = 0; i < 10; i++) {
        if (values[i] < '0' || values[i] > '9') return -1;
    }
    if (output == null || output_capacity < 14) return -2;

    output[0] = '(';
    output[1] = (char)values[0];
    output[2] = (char)values[1];
    output[3] = (char)values[2];
    output[4] = ')';
    output[5] = ' ';
    output[6] = (char)values[3];
    output[7] = (char)values[4];
    output[8] = (char)values[5];
    output[9] = '-';
    for (usz i = 6; i < 10; i++) output[10 + i - 6] = (char)values[i];
    return 14;
}
