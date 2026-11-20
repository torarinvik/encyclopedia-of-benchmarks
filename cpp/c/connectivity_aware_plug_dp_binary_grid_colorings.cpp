#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kCodeStates = 6561;
constexpr std::size_t kMaxStates = 3 * 4 * kCodeStates;

int cell_color(int code) {
    if (code == 0) return -1;
    return code <= 4 ? 0 : 1;
}

bool advance_frontier(const std::array<int, 4>& input_codes, int closed,
                      int diagonal, int color, std::size_t row,
                      std::size_t column, std::array<int, 4>& output_codes,
                      int& output_closed, int& output_diagonal) {
    if (closed & (1 << color)) return false;
    const int above = input_codes[column];
    const int left = column == 0 ? 0 : input_codes[column - 1];
    if (row != 0 && column != 0 && cell_color(above) == color &&
        cell_color(left) == color && diagonal == color + 1) return false;

    output_codes = input_codes;
    output_codes[column] = 0;
    const int above_color = cell_color(above);
    const int above_label = above_color == color ? (color == 0 ? above : above - 4) : 0;
    const int left_label = cell_color(left) == color ? (color == 0 ? left : left - 4) : 0;
    int chosen_label = above_label != 0 ? above_label : left_label;
    if (above_label != 0 && left_label != 0 && above_label != left_label) {
        for (int& code : output_codes) {
            if (color == 0 && code == left_label) code = above_label;
            if (color == 1 && code == 4 + left_label) code = 4 + above_label;
        }
        chosen_label = above_label;
    }
    if (chosen_label == 0) {
        int maximum = 0;
        for (int code : output_codes) {
            if (cell_color(code) == color) {
                const int label = color == 0 ? code : code - 4;
                if (label > maximum) maximum = label;
            }
        }
        chosen_label = maximum + 1;
    }
    output_codes[column] = color == 0 ? chosen_label : 4 + chosen_label;

    output_closed = closed;
    if (above != 0 && above_color != color) {
        bool old_still_present = false;
        bool other_same_color = false;
        for (int code : output_codes) {
            if (code == above) old_still_present = true;
            if (cell_color(code) == above_color && code != above) other_same_color = true;
        }
        if (!old_still_present) {
            if (other_same_color) return false;
            output_closed |= 1 << above_color;
        }
    }

    std::array<int, 9> mapping{};
    std::array<int, 2> next_label{};
    for (int& code : output_codes) {
        if (code == 0) continue;
        if (code <= 4) {
            if (mapping[code] == 0) mapping[code] = ++next_label[0];
            code = mapping[code];
        } else {
            const int key = code - 4;
            if (mapping[4 + key] == 0) mapping[4 + key] = 4 + ++next_label[1];
            code = mapping[4 + key];
        }
    }
    output_diagonal = above_color < 0 ? 0 : above_color + 1;
    return true;
}

std::size_t encode_state(const std::array<int, 4>& codes, int closed, int diagonal) {
    constexpr std::array<std::size_t, 4> powers{1, 9, 81, 729};
    std::size_t code_key = 0;
    for (std::size_t i = 0; i < 4; ++i)
        code_key += static_cast<std::size_t>(codes[i]) * powers[i];
    return (static_cast<std::size_t>(closed) * 3 + static_cast<std::size_t>(diagonal)) *
           kCodeStates + code_key;
}
} // namespace

extern "C" std::int64_t connectivity_aware_plug_dp_binary_grid_colorings(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length != 2) return -1;
    if (input[0] < 2 || input[0] > 4 || input[1] < 2 || input[1] > 4) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);

    std::array<std::int64_t, kMaxStates> dp{};
    std::array<std::int64_t, kMaxStates> next{};
    dp[0] = 1;
    for (std::size_t cell = 0; cell < rows * columns; ++cell) {
        const auto row = cell / columns;
        const auto column = cell % columns;
        next.fill(0);
        for (std::size_t state = 0; state < kMaxStates; ++state) {
            if (dp[state] == 0) continue;
            std::size_t code_key = state % kCodeStates;
            const std::size_t flags = state / kCodeStates;
            const int diagonal = static_cast<int>(flags % 3);
            const int closed = static_cast<int>(flags / 3);
            std::array<int, 4> codes{};
            for (int& code : codes) { code = static_cast<int>(code_key % 9); code_key /= 9; }
            for (int color = 0; color <= 1; ++color) {
                std::array<int, 4> output_codes{};
                int output_closed = 0, output_diagonal = 0;
                if (!advance_frontier(codes, closed, diagonal, color, row, column,
                                      output_codes, output_closed, output_diagonal)) continue;
                next[encode_state(output_codes, output_closed, output_diagonal)] += dp[state];
            }
        }
        dp = next;
    }

    std::int64_t total = 0;
    for (std::size_t state = 0; state < kMaxStates; ++state) {
        if (dp[state] == 0) continue;
        std::size_t code_key = state % kCodeStates;
        const int closed = static_cast<int>((state / kCodeStates) / 3);
        std::array<bool, 5> seen_black{}, seen_white{};
        int black_components = 0, white_components = 0;
        for (std::size_t i = 0; i < 4; ++i) {
            const int code = static_cast<int>(code_key % 9); code_key /= 9;
            if (code >= 1 && code <= 4 && !seen_black[code]) {
                seen_black[code] = true; ++black_components;
            } else if (code >= 5 && code <= 8 && !seen_white[code - 4]) {
                seen_white[code - 4] = true; ++white_components;
            }
        }
        if (((closed & 1) ? black_components == 0 : black_components == 1) &&
            ((closed & 2) ? white_components == 0 : white_components == 1)) total += dp[state];
    }
    return total;
}
