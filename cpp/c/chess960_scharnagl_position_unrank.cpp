#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaximumPositions = 960;
constexpr std::size_t kMaximumInputWords = 962;
constexpr std::array<std::size_t, 10> kKnightFirst{0, 0, 0, 0, 1, 1, 1, 2, 2, 3};
constexpr std::array<std::size_t, 10> kKnightSecond{1, 2, 3, 4, 2, 3, 4, 3, 4, 4};

std::array<std::uint8_t, 8> unrank_position(std::int64_t identifier) {
    std::array<std::uint8_t, 8> board{};
    auto remainder = static_cast<std::uint64_t>(identifier);
    const auto odd_bishop = static_cast<std::size_t>(remainder % 4) * 2 + 1;
    remainder /= 4;
    const auto even_bishop = static_cast<std::size_t>(remainder % 4) * 2;
    remainder /= 4;
    const auto queen_ordinal = static_cast<std::size_t>(remainder % 6);
    const auto knight_ordinal = static_cast<std::size_t>(remainder / 6);
    board[odd_bishop] = 'B';
    board[even_bishop] = 'B';
    std::array<std::size_t, 8> open_files{};
    std::size_t open_count = 0;
    for (std::size_t file = 0; file < 8; ++file)
        if (board[file] == 0) open_files[open_count++] = file;
    board[open_files[queen_ordinal]] = 'Q';
    open_count = 0;
    for (std::size_t file = 0; file < 8; ++file)
        if (board[file] == 0) open_files[open_count++] = file;
    board[open_files[kKnightFirst[knight_ordinal]]] = 'N';
    board[open_files[kKnightSecond[knight_ordinal]]] = 'N';
    constexpr std::array<std::uint8_t, 3> final_pieces{'R', 'K', 'R'};
    std::size_t next_piece = 0;
    for (auto& piece : board) if (piece == 0) piece = final_pieces[next_piece++];
    return board;
}
}

extern "C" std::int64_t chess960_scharnagl_position_unrank(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaximumInputWords) return -1;
    const auto count_word = input[0];
    if (count_word < 0 || count_word > static_cast<std::int64_t>(kMaximumPositions) ||
        length != static_cast<std::size_t>(count_word) + 1) return -1;
    const auto count = static_cast<std::size_t>(count_word);
    for (std::size_t item = 0; item < count; ++item)
        if (input[item + 1] < 0 || input[item + 1] >= static_cast<std::int64_t>(kMaximumPositions)) return -1;
    const auto bytes = count * 8;
    if (bytes != 0 && (output == nullptr || capacity < bytes)) return -2;
    for (std::size_t item = 0; item < count; ++item) {
        const auto board = unrank_position(input[item + 1]);
        for (std::size_t file = 0; file < 8; ++file) output[item * 8 + file] = board[file];
    }
    return static_cast<std::int64_t>(bytes);
}
