#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 41
#define MAX_PARSEABLE_LENGTH 43
#define MAX_OUTPUT_LENGTH 64

typedef struct { uint8_t bytes[MAX_OUTPUT_LENGTH]; size_t length; } byte_writer;

static const char *const color_names[12] = {
    "Black", "Brown", "Red", "Orange", "Yellow", "Green",
    "Blue", "Violet", "Grey", "White", "Gold", "Silver"
};

static int color_code(const int64_t *values, size_t start, size_t end) {
    for (int color = 0; color < 12; ++color) {
        const char *name = color_names[color];
        size_t length = 0;
        while (name[length] != '\0') ++length;
        if (length != end - start) continue;
        size_t i = 0;
        while (i < length && values[start + i + 1] == (unsigned char)name[i]) ++i;
        if (i == length) return color;
    }
    return -1;
}

static void append_byte(byte_writer *writer, uint8_t byte) {
    writer->bytes[writer->length++] = byte;
}

static void append_text(byte_writer *writer, const char *text) {
    while (*text != '\0') append_byte(writer, (uint8_t)*text++);
}

static void append_uint(byte_writer *writer, uint64_t value) {
    uint8_t digits[24];
    size_t count = 0;
    do { digits[count++] = (uint8_t)('0' + value % 10); value /= 10; } while (value != 0);
    while (count > 0) append_byte(writer, digits[--count]);
}

static int append_float_override(byte_writer *writer, unsigned significant, int multiplier) {
    const unsigned target = (unsigned)multiplier * 1000u + significant;
    size_t low = 0, high = 481;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        const size_t offset = middle * 26;
        unsigned key = 0;
        for (size_t i = 0; i < 5; ++i) key = key * 10u + (unsigned)(FLOAT_REPR_TABLE[offset + i] - '0');
        if (key < target) low = middle + 1;
        else if (key > target) high = middle;
        else {
            for (size_t i = offset + 6; i < offset + 25 && FLOAT_REPR_TABLE[i] != ' '; ++i)
                append_byte(writer, (uint8_t)FLOAT_REPR_TABLE[i]);
            return 1;
        }
    }
    return 0;
}

static int tolerance_allowed(int color) {
    return (color >= 1 && color <= 8) || color == 10 || color == 11;
}

int64_t resistor_color_code(const int64_t *values, size_t length,
                            uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t text_length = values[0];
    if (text_length < 1 || text_length > MAX_TEXT_LENGTH || length != (size_t)text_length + 1) return -1;
    for (size_t i = 0; i < (size_t)text_length; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 127) return -1;

    int colors[6];
    size_t color_count = 0, start = 0;
    for (size_t i = 0; i <= (size_t)text_length; ++i) {
        if (i == (size_t)text_length || values[i + 1] == ',') {
            if (color_count == 6 || i == start) return -1;
            const int color = color_code(values, start, i);
            if (color < 0) return -1;
            colors[color_count++] = color;
            start = i + 1;
        }
    }
    if (color_count < 3 || color_count > 6) return -1;

    const size_t significant_count = color_count <= 4 ? 2 : 3;
    unsigned significant = 0;
    for (size_t i = 0; i < significant_count; ++i) {
        if (colors[i] > 9) return -1;
        significant = significant * 10 + (unsigned)colors[i];
    }
    const int multiplier = colors[significant_count];
    const int tolerance_color = color_count >= 4 ? colors[significant_count + 1] : -1;
    const int temperature_color = color_count == 6 ? colors[5] : -1;
    if (tolerance_color >= 0 && !tolerance_allowed(tolerance_color)) return -1;
    if (temperature_color > 8) return -1;

    static const char *const tolerance_text[12] = {
        "", "1", "2", "0.05", "0.02", "0.5", "0.25", "0.1", "0.01", "", "5", "10"
    };
    static const unsigned temperature_values[9] = {250, 100, 50, 15, 25, 20, 10, 5, 1};
    byte_writer writer = {{0}, 0};
    if (multiplier <= 9) {
        uint64_t resistance = significant;
        for (int i = 0; i < multiplier; ++i) resistance *= 10;
        append_uint(&writer, resistance);
    } else if (multiplier == 10) {
        if (!append_float_override(&writer, significant, multiplier)) {
            append_uint(&writer, significant / 10);
            append_byte(&writer, '.');
            append_byte(&writer, (uint8_t)('0' + significant % 10));
        }
    } else {
        if (!append_float_override(&writer, significant, multiplier)) {
            const unsigned whole = significant / 100;
            const unsigned fraction = significant % 100;
            append_uint(&writer, whole);
            append_byte(&writer, '.');
            if (fraction == 0) append_byte(&writer, '0');
            else if (fraction % 10 == 0) append_byte(&writer, (uint8_t)('0' + fraction / 10));
            else { append_byte(&writer, (uint8_t)('0' + fraction / 10)); append_byte(&writer, (uint8_t)('0' + fraction % 10)); }
        }
    }
    append_byte(&writer, 0xCE); append_byte(&writer, 0xA9); /* Ω */
    append_byte(&writer, ' '); append_byte(&writer, 0xC2); append_byte(&writer, 0xB1); /* ± */
    append_text(&writer, tolerance_color < 0 ? "20" : tolerance_text[tolerance_color]);
    append_text(&writer, "% ");
    if (temperature_color >= 0) {
        append_uint(&writer, temperature_values[temperature_color]);
        append_text(&writer, " ppm/K");
    }

    if (capacity < writer.length || (writer.length > 0 && output == NULL)) return -2;
    for (size_t i = 0; i < writer.length; ++i) output[i] = writer.bytes[i];
    return (int64_t)writer.length;
}
