#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t egg_drop_max_floors_by_moves(const std::int64_t *input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto eggs = input[0];
    const auto moves = input[1];
    if (eggs < 0 || eggs > 32 || moves < 0 || moves > 32) return -1;
    std::array<std::int64_t, 33> covered{};
    for (std::int64_t move = 0; move < moves; ++move)
        for (auto egg = eggs; egg > 0; --egg)
            covered[static_cast<std::size_t>(egg)] +=
                covered[static_cast<std::size_t>(egg - 1)] + 1;
    return covered[static_cast<std::size_t>(eggs)];
}
