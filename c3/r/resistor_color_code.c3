module resistor_color_code;

const long MAX_TEXT_LENGTH = 41;
const long MAX_PARSEABLE_LENGTH = 43;

fn int color_code(long* values, usz start, usz end) {
    char*[12] names = {"Black", "Brown", "Red", "Orange", "Yellow", "Green", "Blue", "Violet", "Grey", "White", "Gold", "Silver"};
    for (int color = 0; color < 12; color++) {
        char* name = names[color];
        usz size = 0; while (name[size] != 0) size++;
        if (size != end - start) continue;
        bool same = true;
        for (usz i = 0; i < size; i++) if (values[start + i + 1] != (long)(uchar)name[i]) same = false;
        if (same) return color;
    }
    return -1;
}

fn void append_byte(char* buffer, usz* length, int value) {
    buffer[*length] = (char)value;
    *length = *length + 1;
}

fn void append_text(char* buffer, usz* length, char* text) {
    for (usz i = 0; text[i] != 0; i++) append_byte(buffer, length, (int)(uchar)text[i]);
}

fn void append_uint(char* buffer, usz* length, ulong value) {
    char[24] digits = {};
    usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value != 0);
    while (count > 0) append_byte(buffer, length, (int)(uchar)digits[--count]);
}

fn bool tolerance_allowed(int color) {
    return (color >= 1 && color <= 8) || color == 10 || color == 11;
}

fn long resistor_color_code(long* values, usz length, char* output, usz capacity) @export("resistor_color_code") {
    if (values == null || length < 2 || length > (usz)MAX_PARSEABLE_LENGTH) return -1;
    long text_length = values[0];
    if (text_length < 1 || text_length > MAX_TEXT_LENGTH || length != (usz)(text_length + 1)) return -1;
    for (usz i = 0; i < (usz)text_length; i++) if (values[i + 1] < 0 || values[i + 1] > 127) return -1;

    int[6] colors = {};
    usz color_count = 0, start = 0;
    for (usz i = 0; i <= (usz)text_length; i++) {
        if (i == (usz)text_length || values[i + 1] == ',') {
            if (color_count == 6 || i == start) return -1;
            int color = color_code(values, start, i);
            if (color < 0) return -1;
            colors[color_count++] = color;
            start = i + 1;
        }
    }
    if (color_count < 3 || color_count > 6) return -1;

    usz significant_count = color_count <= 4 ? 2 : 3;
    ulong significant = 0;
    for (usz i = 0; i < significant_count; i++) {
        if (colors[i] > 9) return -1;
        significant = significant * 10 + (ulong)colors[i];
    }
    int multiplier = colors[significant_count];
    int tolerance_color = color_count >= 4 ? colors[significant_count + 1] : -1;
    int temperature_color = color_count == 6 ? colors[5] : -1;
    if (tolerance_color >= 0 && !tolerance_allowed(tolerance_color)) return -1;
    if (temperature_color > 8) return -1;

    char[64] buffer = {};
    usz out_length = 0;
    if (multiplier <= 9) {
        ulong resistance = significant;
        for (int i = 0; i < multiplier; i++) resistance *= 10;
        append_uint(&buffer[0], &out_length, resistance);
    } else if (multiplier == 10) {
        append_uint(&buffer[0], &out_length, significant / 10);
        append_byte(&buffer[0], &out_length, '.');
        append_byte(&buffer[0], &out_length, (int)('0' + significant % 10));
    } else {
        ulong whole = significant / 100, fraction = significant % 100;
        append_uint(&buffer[0], &out_length, whole);
        append_byte(&buffer[0], &out_length, '.');
        if (fraction == 0) append_byte(&buffer[0], &out_length, '0');
        else if (fraction % 10 == 0) append_byte(&buffer[0], &out_length, (int)('0' + fraction / 10));
        else { append_byte(&buffer[0], &out_length, (int)('0' + fraction / 10)); append_byte(&buffer[0], &out_length, (int)('0' + fraction % 10)); }
    }
    append_byte(&buffer[0], &out_length, 0xCE); append_byte(&buffer[0], &out_length, 0xA9);
    append_byte(&buffer[0], &out_length, ' '); append_byte(&buffer[0], &out_length, 0xC2); append_byte(&buffer[0], &out_length, 0xB1);
    if (tolerance_color < 0) append_text(&buffer[0], &out_length, "20");
    else if (tolerance_color == 1) append_text(&buffer[0], &out_length, "1");
    else if (tolerance_color == 2) append_text(&buffer[0], &out_length, "2");
    else if (tolerance_color == 3) append_text(&buffer[0], &out_length, "0.05");
    else if (tolerance_color == 4) append_text(&buffer[0], &out_length, "0.02");
    else if (tolerance_color == 5) append_text(&buffer[0], &out_length, "0.5");
    else if (tolerance_color == 6) append_text(&buffer[0], &out_length, "0.25");
    else if (tolerance_color == 7) append_text(&buffer[0], &out_length, "0.1");
    else if (tolerance_color == 8) append_text(&buffer[0], &out_length, "0.01");
    else if (tolerance_color == 10) append_text(&buffer[0], &out_length, "5");
    else append_text(&buffer[0], &out_length, "10");
    append_text(&buffer[0], &out_length, "% ");
    if (temperature_color >= 0) {
        ulong temperature = temperature_color == 0 ? 250 : temperature_color == 1 ? 100 : temperature_color == 2 ? 50 : temperature_color == 3 ? 15 : temperature_color == 4 ? 25 : temperature_color == 5 ? 20 : temperature_color == 6 ? 10 : temperature_color == 7 ? 5 : 1;
        append_uint(&buffer[0], &out_length, temperature);
        append_text(&buffer[0], &out_length, " ppm/K");
    }
    if (capacity < out_length || (output == null && out_length > 0)) return -2;
    for (usz i = 0; i < out_length; i++) output[i] = buffer[i];
    return (long)out_length;
}
