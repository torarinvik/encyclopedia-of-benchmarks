#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kBits = 64, kBlock = 8, kBase = 16, kLevels = 3;
constexpr std::size_t kInput = 66, kWords = 1 + kBits;

struct Group { std::uint16_t key{}; std::uint8_t start{}, count{}, cursor{}; };
struct Level {
    std::size_t length{};
    std::array<std::uint8_t, kBits> bits{}, mate{}, far{}, family{};
    std::array<std::int16_t, kBits> family_rank{};
    std::array<std::int16_t, kBits + 1> depth{};
    std::array<std::uint8_t, kBits> open_pioneer{}, close_pioneer{};
    std::array<Group, kBits> open_groups{}, close_groups{};
    std::array<std::uint8_t, kBits> open_members{}, close_members{};
    std::size_t open_group_count{}, close_group_count{};
};
std::array<Level, kLevels> levels{};

std::uint16_t group_key(std::size_t source, std::size_t target, int depth) {
    return static_cast<std::uint16_t>((source << 10) | (target << 7) | static_cast<unsigned>(depth));
}

std::size_t find_group(const std::array<Group, kBits>& groups, std::size_t count,
                       std::uint16_t key) {
    for (std::size_t i = 0; i < count; ++i) if (groups[i].key == key) return i;
    return kBits;
}

void build_groups(Level& a, const std::array<std::int16_t, kBits>& targets) {
    for (std::size_t position = 0; position < a.length; ++position) {
        if (!a.far[position]) continue;
        const auto source = position / kBlock;
        const auto target = static_cast<std::size_t>(targets[position]);
        const int depth = a.bits[position] ? a.depth[position] : a.depth[position + 1];
        auto& groups = a.bits[position] ? a.open_groups : a.close_groups;
        auto& group_count = a.bits[position] ? a.open_group_count : a.close_group_count;
        auto index = find_group(groups, group_count, group_key(source, target, depth));
        if (index == kBits) {
            index = group_count++;
            groups[index].key = group_key(source, target, depth);
            groups[index].count = 0;
        }
        ++groups[index].count;
    }
    std::size_t open_offset = 0, close_offset = 0;
    for (std::size_t i = 0; i < a.open_group_count; ++i) {
        a.open_groups[i].start = static_cast<std::uint8_t>(open_offset);
        a.open_groups[i].cursor = 0;
        open_offset += a.open_groups[i].count;
    }
    for (std::size_t i = 0; i < a.close_group_count; ++i) {
        a.close_groups[i].start = static_cast<std::uint8_t>(close_offset);
        a.close_groups[i].cursor = 0;
        close_offset += a.close_groups[i].count;
    }
    for (std::size_t position = 0; position < a.length; ++position) {
        if (!a.far[position]) continue;
        const auto source = position / kBlock;
        const auto target = static_cast<std::size_t>(targets[position]);
        const int depth = a.bits[position] ? a.depth[position] : a.depth[position + 1];
        auto& groups = a.bits[position] ? a.open_groups : a.close_groups;
        const auto count = a.bits[position] ? a.open_group_count : a.close_group_count;
        auto& members = a.bits[position] ? a.open_members : a.close_members;
        const auto index = find_group(groups, count, group_key(source, target, depth));
        auto& group = groups[index];
        members[group.start + group.cursor++] = static_cast<std::uint8_t>(position);
    }
}

bool build_level(std::size_t level, const std::array<std::uint8_t, kBits>& bits,
                 std::size_t length) {
    if (level >= kLevels || length > kBits) return false;
    auto& a = levels[level];
    a.length = length;
    std::array<std::size_t, kBits> stack{};
    std::array<std::uint8_t, kBits> matched{};
    std::array<std::int16_t, kBits> targets{};
    std::size_t top = 0;
    for (std::size_t i = 0; i < length; ++i) {
        a.bits[i] = bits[i]; a.mate[i] = 0; a.far[i] = 0; a.family[i] = 0;
        a.family_rank[i] = -1; a.open_pioneer[i] = 0; a.close_pioneer[i] = 0;
        targets[i] = -1;
        if (bits[i]) stack[top++] = i;
        else {
            if (top == 0) return false;
            const auto opening = stack[--top];
            matched[opening] = static_cast<std::uint8_t>(i);
            matched[i] = static_cast<std::uint8_t>(opening);
        }
    }
    if (top != 0) return false;
    a.depth[0] = 0;
    for (std::size_t i = 0; i < length; ++i)
        a.depth[i + 1] = static_cast<std::int16_t>(a.depth[i] + (bits[i] ? 1 : -1));
    if (length <= kBase) {
        for (std::size_t i = 0; i < length; ++i) a.mate[i] = matched[i];
        return true;
    }

    a.open_group_count = 0; a.close_group_count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const auto target = static_cast<std::size_t>(matched[i]) / kBlock;
        if (target == i / kBlock) a.mate[i] = matched[i];
        else { a.far[i] = 1; targets[i] = static_cast<std::int16_t>(target); }
    }
    build_groups(a, targets);

    for (std::size_t start = 0; start < length; start += kBlock) {
        const auto end = std::min(start + kBlock, length);
        int previous_target = -1;
        for (std::size_t i = start; i < end; ++i) {
            if (!bits[i] || !a.far[i]) continue;
            const int target = targets[i];
            if (previous_target < 0 || target != previous_target) a.open_pioneer[i] = 1;
            previous_target = target;
        }
        int next_target = -1;
        for (std::size_t i = end; i-- > start;) {
            if (bits[i] || !a.far[i]) continue;
            const int target = targets[i];
            if (next_target < 0 || target != next_target) a.close_pioneer[i] = 1;
            next_target = target;
        }
    }
    for (std::size_t i = 0; i < length; ++i) {
        if (a.open_pioneer[i] || a.close_pioneer[i]) {
            a.family[i] = 1; a.family[matched[i]] = 1;
        }
    }
    std::array<std::uint8_t, kBits> child{};
    std::size_t count = 0;
    for (std::size_t i = 0; i < length; ++i) if (a.family[i]) {
        a.family_rank[i] = static_cast<std::int16_t>(count);
        child[count++] = a.bits[i];
    }
    return count > 0 && count < length && build_level(level + 1, child, count);
}

bool find_pioneer(const Level& a, std::size_t position, std::size_t& pioneer) {
    const auto block_start = (position / kBlock) * kBlock;
    if (a.bits[position]) {
        for (std::size_t i = position + 1; i-- > block_start;)
            if (a.open_pioneer[i]) { pioneer = i; return true; }
    } else {
        const auto end = std::min(block_start + kBlock, a.length);
        for (std::size_t i = position; i < end; ++i)
            if (a.close_pioneer[i]) { pioneer = i; return true; }
    }
    return false;
}

bool match_position(std::size_t level, std::size_t position, std::size_t& answer) {
    const auto& a = levels[level];
    if (position >= a.length) return false;
    if (a.length <= kBase || !a.far[position]) { answer = a.mate[position]; return true; }
    std::size_t pioneer;
    if (!find_pioneer(a, position, pioneer)) return false;
    std::size_t child_match;
    if (!match_position(level + 1, static_cast<std::size_t>(a.family_rank[pioneer]), child_match)) return false;
    const auto anchor = static_cast<std::size_t>(a.family[child_match]);
    const auto source = position / kBlock, target = anchor / kBlock;
    int target_depth;
    if (a.bits[position]) {
        const int relative_excess = a.depth[position] - a.depth[pioneer];
        target_depth = a.depth[pioneer] + relative_excess;
        const auto src = find_group(a.open_groups, a.open_group_count, group_key(source, target, target_depth));
        const auto dst = find_group(a.close_groups, a.close_group_count, group_key(target, source, target_depth));
        if (src == kBits || dst == kBits) return false;
        const auto left = a.open_groups[src], right = a.close_groups[dst];
        std::size_t rank = 0;
        while (rank < left.count && a.open_members[left.start + rank] != position) ++rank;
        if (rank >= left.count || rank >= right.count) return false;
        answer = a.close_members[right.start + rank];
        return true;
    }
    const int relative_excess = a.depth[position + 1] - a.depth[pioneer + 1];
    target_depth = a.depth[pioneer + 1] + relative_excess;
    const auto src = find_group(a.close_groups, a.close_group_count, group_key(source, target, target_depth));
    const auto dst = find_group(a.open_groups, a.open_group_count, group_key(target, source, target_depth));
    if (src == kBits || dst == kBits) return false;
    const auto left = a.close_groups[src], right = a.open_groups[dst];
    std::size_t rank = 0;
    while (rank < left.count && a.close_members[left.start + rank] != position) ++rank;
    if (rank >= left.count || rank >= right.count) return false;
    answer = a.open_members[right.start + rank];
    return true;
}

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t succinct_bp_pioneer_match_index(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > kInput) return -1;
    const auto n = input[0];
    if (n < 1 || n > 32 || length != 1 + 2 * static_cast<std::size_t>(n)) return -1;
    const auto bit_count = 2 * static_cast<std::size_t>(n);
    std::array<std::uint8_t, kBits> bits{};
    int balance = 0;
    for (std::size_t i = 0; i < bit_count; ++i) {
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
        bits[i] = static_cast<std::uint8_t>(input[i + 1]);
        balance += bits[i] ? 1 : -1;
        if (balance < 0) return -1;
    }
    if (balance != 0 || !build_level(0, bits, bit_count)) return -1;
    const auto required = 8 * (1 + bit_count);
    if (output == nullptr || capacity < required) return -2;
    std::array<std::int64_t, kWords> words{};
    words[0] = static_cast<std::int64_t>(bit_count);
    for (std::size_t i = 0; i < bit_count; ++i) {
        std::size_t mate;
        if (!match_position(0, i, mate)) return -1;
        words[i + 1] = static_cast<std::int64_t>(mate);
    }
    for (std::size_t i = 0; i < 1 + bit_count; ++i) write_i64_le(output, 8 * i, words[i]);
    return static_cast<std::int64_t>(required);
}
