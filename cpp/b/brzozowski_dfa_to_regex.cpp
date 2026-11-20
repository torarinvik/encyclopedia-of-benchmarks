#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>

namespace {
constexpr std::size_t kStates = 3;
constexpr std::size_t kText = 512;

std::size_t text_length(const char *text) {
    std::size_t length = 0;
    while (text[length] != '\0') ++length;
    return length;
}

bool text_copy(char *output, const char *source) {
    if (output == source) return true;
    const auto length = text_length(source);
    if (length >= kText) return false;
    std::memcpy(output, source, length + 1);
    return true;
}

bool regex_union(char *output, const char *left, const char *right) {
    if (std::strcmp(left, "#") == 0) return text_copy(output, right);
    if (std::strcmp(right, "#") == 0 || std::strcmp(left, right) == 0)
        return text_copy(output, left);
    const char *first = std::strcmp(left, right) < 0 ? left : right;
    const char *second = first == left ? right : left;
    char temporary[kText];
    const int written = std::snprintf(temporary, sizeof temporary, "(%s|%s)", first, second);
    if (written < 0 || static_cast<std::size_t>(written) >= sizeof temporary) return false;
    return text_copy(output, temporary);
}

bool regex_concat(char *output, const char *left, const char *right) {
    if (std::strcmp(left, "#") == 0 || std::strcmp(right, "#") == 0)
        return text_copy(output, "#");
    if (std::strcmp(left, "@") == 0) return text_copy(output, right);
    if (std::strcmp(right, "@") == 0) return text_copy(output, left);
    char temporary[kText];
    const int written = std::snprintf(temporary, sizeof temporary, "(%s.%s)", left, right);
    if (written < 0 || static_cast<std::size_t>(written) >= sizeof temporary) return false;
    return text_copy(output, temporary);
}

bool regex_star(char *output, const char *value) {
    if (std::strcmp(value, "#") == 0 || std::strcmp(value, "@") == 0)
        return text_copy(output, "@");
    char temporary[kText];
    const int written = std::snprintf(temporary, sizeof temporary, "(%s)*", value);
    if (written < 0 || static_cast<std::size_t>(written) >= sizeof temporary) return false;
    return text_copy(output, temporary);
}
} // namespace

extern "C" std::int64_t brzozowski_dfa_to_regex(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 10) return -1;
    const auto n64 = input[0], start64 = input[1], accepting = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(kStates)
        || start64 < 0 || start64 >= n64 || accepting < 0
        || accepting >= (std::int64_t{1} << n64)
        || length != 3 + 2 * static_cast<std::size_t>(n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto start = static_cast<std::size_t>(start64);
    char coefficient[kStates][kStates][kText];
    char constant[kStates][kText];
    for (std::size_t state = 0; state < n; ++state) {
        if (!text_copy(constant[state], (accepting & (std::int64_t{1} << state)) ? "@" : "#"))
            return -1;
        for (std::size_t target = 0; target < n; ++target)
            if (!text_copy(coefficient[state][target], "#")) return -1;
        for (std::size_t symbol = 0; symbol < 2; ++symbol) {
            const auto next = input[3 + 2 * state + symbol];
            if (next < 0 || next >= n64) return -1;
            const char label[2] = {static_cast<char>('0' + symbol), '\0'};
            if (!regex_union(coefficient[state][next], coefficient[state][next], label)) return -1;
        }
    }

    for (std::size_t pivot = 0; pivot < n; ++pivot) {
        if (pivot == start) continue;
        char loop[kText];
        if (!regex_star(loop, coefficient[pivot][pivot])) return -1;
        for (std::size_t source = 0; source < n; ++source) {
            if (source == pivot) continue;
            char prefix[kText];
            if (!regex_concat(prefix, coefficient[source][pivot], loop)) return -1;
            for (std::size_t target = 0; target < n; ++target) {
                if (target == pivot) continue;
                char through[kText];
                if (!regex_concat(through, prefix, coefficient[pivot][target])
                    || !regex_union(coefficient[source][target], coefficient[source][target], through))
                    return -1;
            }
            char through_constant[kText];
            if (!regex_concat(through_constant, prefix, constant[pivot])
                || !regex_union(constant[source], constant[source], through_constant)) return -1;
        }
    }
    char loop[kText], answer[kText];
    if (!regex_star(loop, coefficient[start][start]) || !regex_concat(answer, loop, constant[start]))
        return -1;
    const auto result_length = text_length(answer);
    if (result_length > 270) return -1;
    if (output == nullptr || capacity < result_length) return -2;
    std::memcpy(output, answer, result_length);
    return static_cast<std::int64_t>(result_length);
}
