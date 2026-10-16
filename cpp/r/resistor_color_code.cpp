#include <array>
#include <cstddef>
#include <cstdint>
#include <string>

static constexpr std::int64_t MAX_TEXT_LENGTH = 41;
static constexpr std::int64_t MAX_PARSEABLE_LENGTH = 43;
static constexpr std::array<const char*, 12> COLOR_NAMES = {
    "Black", "Brown", "Red", "Orange", "Yellow", "Green",
    "Blue", "Violet", "Grey", "White", "Gold", "Silver"
};

static int color_code(const std::int64_t* values, std::size_t start, std::size_t end) {
    for (int color = 0; color < 12; ++color) {
        const std::string name = COLOR_NAMES[static_cast<std::size_t>(color)];
        if (name.size() != end - start) continue;
        bool same = true;
        for (std::size_t i = 0; i < name.size(); ++i)
            if (values[start + i + 1] != static_cast<unsigned char>(name[i])) same = false;
        if (same) return color;
    }
    return -1;
}

static void append_uint(std::string& output, std::uint64_t value) {
    output += std::to_string(value);
}

static bool tolerance_allowed(int color) {
    return (color >= 1 && color <= 8) || color == 10 || color == 11;
}

extern "C" std::int64_t resistor_color_code(const std::int64_t* values,
                                              std::size_t length,
                                              std::uint8_t* output,
                                              std::size_t capacity) {
    if (values == nullptr || length < 2 || length > static_cast<std::size_t>(MAX_PARSEABLE_LENGTH)) return -1;
    const std::int64_t text_length = values[0];
    if (text_length < 1 || text_length > MAX_TEXT_LENGTH || length != static_cast<std::size_t>(text_length + 1)) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i)
        if (values[i + 1] < 0 || values[i + 1] > 127) return -1;

    std::array<int, 6> colors{};
    std::size_t color_count = 0, start = 0;
    for (std::size_t i = 0; i <= static_cast<std::size_t>(text_length); ++i) {
        if (i == static_cast<std::size_t>(text_length) || values[i + 1] == ',') {
            if (color_count == colors.size() || i == start) return -1;
            const int color = color_code(values, start, i);
            if (color < 0) return -1;
            colors[color_count++] = color;
            start = i + 1;
        }
    }
    if (color_count < 3 || color_count > 6) return -1;

    const std::size_t significant_count = color_count <= 4 ? 2 : 3;
    unsigned significant = 0;
    for (std::size_t i = 0; i < significant_count; ++i) {
        if (colors[i] > 9) return -1;
        significant = significant * 10 + static_cast<unsigned>(colors[i]);
    }
    const int multiplier = colors[significant_count];
    const int tolerance_color = color_count >= 4 ? colors[significant_count + 1] : -1;
    const int temperature_color = color_count == 6 ? colors[5] : -1;
    if (tolerance_color >= 0 && !tolerance_allowed(tolerance_color)) return -1;
    if (temperature_color > 8) return -1;

    static constexpr std::array<const char*, 12> TOLERANCE_TEXT = {
        "", "1", "2", "0.05", "0.02", "0.5", "0.25", "0.1", "0.01", "", "5", "10"
    };
    static constexpr std::array<unsigned, 9> TEMPERATURE_VALUES = {250, 100, 50, 15, 25, 20, 10, 5, 1};
    std::string answer;
    if (multiplier <= 9) {
        std::uint64_t resistance = significant;
        for (int i = 0; i < multiplier; ++i) resistance *= 10;
        append_uint(answer, resistance);
    } else if (multiplier == 10) {
        append_uint(answer, significant / 10);
        answer += '.';
        answer += static_cast<char>('0' + significant % 10);
    } else {
        const unsigned whole = significant / 100;
        const unsigned fraction = significant % 100;
        append_uint(answer, whole);
        answer += '.';
        if (fraction == 0) answer += '0';
        else if (fraction % 10 == 0) answer += static_cast<char>('0' + fraction / 10);
        else {
            answer += static_cast<char>('0' + fraction / 10);
            answer += static_cast<char>('0' + fraction % 10);
        }
    }
    answer += std::string("\xCE\xA9", 2); // Ω
    answer += ' ';
    answer += std::string("\xC2\xB1", 2); // ±
    answer += tolerance_color < 0 ? "20" : TOLERANCE_TEXT[static_cast<std::size_t>(tolerance_color)];
    answer += "% ";
    if (temperature_color >= 0) {
        append_uint(answer, TEMPERATURE_VALUES[static_cast<std::size_t>(temperature_color)]);
        answer += " ppm/K";
    }
    if (capacity < answer.size() || (output == nullptr && !answer.empty())) return -2;
    for (std::size_t i = 0; i < answer.size(); ++i) output[i] = static_cast<std::uint8_t>(answer[i]);
    return static_cast<std::int64_t>(answer.size());
}
