#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t piece_count = 9;
constexpr int position_count = 18;
constexpr int max_depth = 8;
using State = std::array<int, piece_count>;
using MoveMap = std::array<int, position_count>;

constexpr std::array<MoveMap, 3> upper_moves{{
    {{0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6}},
    {{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}},
    {{1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16}}
}};
constexpr std::array<MoveMap, 3> lower_moves{{
    {{0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16}},
    {{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}},
    {{7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5}}
}};
constexpr std::array<int, position_count> near_mask{{
    0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70,
    0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f
}};

bool near_enough(const State &state) {
    return (near_mask[state[1]] & 0x02) != 0
        && (near_mask[state[3]] & 0x08) != 0
        && (near_mask[state[4]] & 0x10) != 0
        && (near_mask[state[5]] & 0x20) != 0
        && (near_mask[state[0]] & 0x01) != 0
        && (near_mask[state[2]] & 0x04) != 0
        && (near_mask[state[6]] & 0x40) != 0
        && (near_mask[state[7]] & 0x40) != 0
        && (near_mask[state[8]] & 0x40) != 0;
}

bool is_goal(const State &state) {
    return state[0] == 5 && state[1] == 6 && state[2] == 12
        && state[3] == 13 && state[4] == 14 && state[5] == 15
        && state[6] + state[7] + state[8] == 3;
}

State apply_move(const State &state, const MoveMap &map) {
    State next{};
    for (std::size_t piece = 0; piece < piece_count; ++piece)
        next[piece] = map[static_cast<std::size_t>(state[piece])];
    return next;
}

bool search_down(const State &state, int bound, int depth, int last_move);

bool search_up(const State &state, int bound, int depth, int last_move) {
    if (depth == bound - 4 && !near_enough(state)) return false;
    if (is_goal(state)) return true;
    if (bound <= depth) return false;
    for (int move = 0; move < 3; ++move) {
        if (move == last_move) continue;
        const State next = apply_move(state, upper_moves[static_cast<std::size_t>(move)]);
        if (search_down(next, bound, depth + 1, move)) return true;
    }
    return false;
}

bool search_down(const State &state, int bound, int depth, int last_move) {
    if (bound <= depth) return false;
    for (int move = 0; move < 3; ++move) {
        if (move == last_move) continue;
        const State next = apply_move(state, lower_moves[static_cast<std::size_t>(move)]);
        if (search_up(next, bound, depth + 1, move)) return true;
    }
    return false;
}
}

extern "C" std::int64_t freebench_mason(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != piece_count) return -1;
    State start{};
    unsigned int used = 0;
    for (std::size_t piece = 0; piece < piece_count; ++piece) {
        const std::int64_t position = input[piece];
        if (position < 0 || position >= position_count) return -1;
        const unsigned int bit = 1u << static_cast<unsigned int>(position);
        if ((used & bit) != 0) return -1;
        used |= bit;
        start[piece] = static_cast<int>(position);
    }
    for (int bound = 2; bound <= max_depth; bound += 2)
        if (search_up(start, bound, 0, -1)) return bound;
    return -2;
}
