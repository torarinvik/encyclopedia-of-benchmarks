module hill_cipher_mod36;

fn int symbol_value(long value) {
    if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
    if (value >= 'A' && value <= 'Z') return (int)(value - 'A');
    if (value >= '0' && value <= '9') return (int)(value - '0') + 26;
    return -1;
}
fn char output_symbol(int value) { return (char)(value < 26 ? 'A' + value : '0' + value - 26); }

fn long hill_cipher_mod36(long* input, usz length, char* output, usz capacity) @export("hill_cipher_mod36") {
    if (input == null || length < 3 || input[0] < 0 || input[0] > 1) return -1;
    long raw_length = input[1];
    if (raw_length < 1 || raw_length > 256 || length != (usz)(raw_length + 2)) return -1;
    int[256] text; usz count = 0;
    for (usz i = 0; i < (usz)raw_length; i++) {
        long byte = input[2+i]; if (byte < 0 || byte > 127) return -1;
        int value = symbol_value(byte); if (value >= 0) text[count++] = value;
    }
    if (count == 0) return -1;
    if (count % 2 != 0) { text[count] = text[count-1]; count++; }
    if (output == null || capacity < count) return -2;
    bool decrypt = input[0] == 1;
    for (usz i = 0; i < count; i += 2) {
        int a=text[i], b=text[i+1];
        int first = decrypt ? (6*a+25*b)%36 : (2*a+5*b)%36;
        int second = decrypt ? (5*a+26*b)%36 : (a+6*b)%36;
        output[i] = output_symbol(first); output[i+1] = output_symbol(second);
    }
    return (long)count;
}
