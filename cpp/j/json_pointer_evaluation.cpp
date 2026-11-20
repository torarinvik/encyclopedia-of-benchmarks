#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 32, max_pointer = 64, record_words = 21;
std::int64_t field(const std::int64_t *values, std::size_t base,
                   std::size_t node, std::size_t offset) noexcept {
    return values[base + node * record_words + offset];
}
}

extern "C" std::int64_t json_pointer_evaluation(const std::int64_t *values,
                                                  std::size_t length) noexcept {
    if (values == nullptr || length < 3) return -1;
    const auto n_value = values[0], root_value = values[1], pointer_value = values[2];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_nodes)
        || root_value < 0 || root_value >= n_value || pointer_value < 0
        || pointer_value > static_cast<std::int64_t>(max_pointer)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto root = static_cast<std::size_t>(root_value);
    const auto pointer_length = static_cast<std::size_t>(pointer_value);
    const auto base = 3 + pointer_length;
    if (length != base + n * record_words) return -1;
    for (std::size_t i = 0; i < pointer_length; ++i)
        if (values[3 + i] < 0 || values[3 + i] > 127) return -1;
    if (pointer_length != 0 && values[3] != '/') return -1;
    for (std::size_t syntax_pos = 1; syntax_pos < pointer_length; ++syntax_pos) {
        if (values[3 + syntax_pos] != '~') continue;
        if (++syntax_pos >= pointer_length) return -1;
        const auto escaped = values[3 + syntax_pos];
        if (escaped != '0' && escaped != '1') return -1;
    }

    for (std::size_t i = 0; i < n; ++i) {
        const auto kind = field(values, base, i, 0);
        const auto parent = field(values, base, i, 1);
        const auto key_length = field(values, base, i, 2);
        const auto array_index = field(values, base, i, 19);
        if (kind < 0 || kind > 2 || key_length < 0 || key_length > 16) return -1;
        if (i == root) {
            if (parent != -1 || key_length != 0 || array_index != -1) return -1;
        } else {
            if (parent < 0 || parent >= n_value || static_cast<std::size_t>(parent) == i) return -1;
            const auto parent_kind = field(values, base, static_cast<std::size_t>(parent), 0);
            if (parent_kind < 0 || parent_kind > 1) return -1;
            if (parent_kind == 0) { if (array_index != -1) return -1; }
            else if (key_length != 0 || array_index < 0) return -1;
        }
        for (std::size_t k = 0; k < 16; ++k) {
            const auto ch = field(values, base, i, 3 + k);
            if (k < static_cast<std::size_t>(key_length)) {
                if (ch < 0 || ch > 127) return -1;
            } else if (ch != 0) return -1;
        }
        auto cursor = i;
        std::size_t hops = 0;
        while (cursor != root && hops < n) {
            const auto next = field(values, base, cursor, 1);
            if (next < 0 || next >= n_value) return -1;
            cursor = static_cast<std::size_t>(next);
            ++hops;
        }
        if (cursor != root) return -1;
    }
    for (std::size_t parent = 0; parent < n; ++parent) {
        if (field(values, base, parent, 0) != 1) continue;
        std::size_t children = 0;
        for (std::size_t child = 0; child < n; ++child)
            if (field(values, base, child, 1) == static_cast<std::int64_t>(parent)) ++children;
        for (std::size_t child = 0; child < n; ++child) {
            if (field(values, base, child, 1) != static_cast<std::int64_t>(parent)) continue;
            const auto index = field(values, base, child, 19);
            if (index < 0 || static_cast<std::uint64_t>(index) >= children) return -1;
            for (std::size_t prior = 0; prior < child; ++prior)
                if (field(values, base, prior, 1) == static_cast<std::int64_t>(parent)
                    && field(values, base, prior, 19) == index) return -1;
        }
    }

    auto current = root;
    if (pointer_length == 0) return static_cast<std::int64_t>(current);
    std::array<std::int64_t, max_pointer> token{};
    std::size_t token_length = 0;
    for (std::size_t pos = 1; pos <= pointer_length; ++pos) {
        if (pos == pointer_length || values[3 + pos] == '/') {
            const auto kind = field(values, base, current, 0);
            std::size_t found = n, matches = 0;
            if (kind == 0) {
                for (std::size_t child = 0; child < n; ++child) {
                    if (field(values, base, child, 1) != static_cast<std::int64_t>(current)
                        || field(values, base, child, 2) != static_cast<std::int64_t>(token_length)) continue;
                    std::size_t k = 0;
                    while (k < token_length && field(values, base, child, 3 + k) == token[k]) ++k;
                    if (k == token_length) { found = child; ++matches; }
                }
            } else if (kind == 1) {
                if (token_length == 0 || (token_length > 1 && token[0] == '0')) return -2;
                std::int64_t index = 0;
                for (std::size_t k = 0; k < token_length; ++k) {
                    if (token[k] < '0' || token[k] > '9') return -2;
                    index = index * 10 + token[k] - '0';
                    if (index > static_cast<std::int64_t>(max_nodes)) return -2;
                }
                for (std::size_t child = 0; child < n; ++child)
                    if (field(values, base, child, 1) == static_cast<std::int64_t>(current)
                        && field(values, base, child, 19) == index) { found = child; ++matches; }
            } else return -2;
            if (matches != 1) return -2;
            current = found;
            token_length = 0;
            continue;
        }
        auto ch = values[3 + pos];
        if (ch == '~') {
            if (++pos >= pointer_length) return -1;
            const auto escaped = values[3 + pos];
            if (escaped == '0') ch = '~';
            else if (escaped == '1') ch = '/';
            else return -1;
        }
        token[token_length++] = ch;
    }
    return static_cast<std::int64_t>(current);
}
