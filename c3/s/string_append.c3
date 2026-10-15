module string_append;

fn long string_append(long* input, usz length, char* output, usz output_capacity)
        @export("string_append") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 64) return -1;
    usz first_length = (usz)input[0];
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64) return -1;
    usz second_length = (usz)input[1 + first_length];
    if (length != 2 + first_length + second_length) return -1;
    for (usz i = 0; i < first_length; i++) if (input[2 + i] < 32 || input[2 + i] > 126) return -1;
    for (usz i = 0; i < second_length; i++) if (input[2 + first_length + i] < 32 || input[2 + first_length + i] > 126) return -1;
    usz count = first_length + second_length;
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz i = 0; i < first_length; i++) output[i] = (char)input[2 + i];
    for (usz i = 0; i < second_length; i++) output[first_length + i] = (char)input[2 + first_length + i];
    return (long)count;
}
