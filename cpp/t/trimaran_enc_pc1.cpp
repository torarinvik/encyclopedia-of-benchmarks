/* Pukall Cipher 1 adaptation for the bounded Trimaran profile.
   Source author: Alexander Pukall (1991); source grants unrestricted use. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_num_input = 2049;
struct State { std::uint16_t words[16]{}; std::uint16_t si = 0, x1a2 = 0; };

std::uint16_t code_step(State& s, std::uint16_t index) {
    std::uint16_t dx = static_cast<std::uint16_t>(s.x1a2 + index);
    std::uint16_t ax = s.words[index], cx = 0x015a, tmp = ax;
    constexpr std::uint16_t bx = 0x4e35;
    ax = s.si; s.si = tmp; tmp = ax; ax = dx; dx = tmp;
    if (ax != 0) ax = static_cast<std::uint16_t>(std::uint32_t(ax) * bx);
    tmp = ax; ax = cx; cx = tmp;
    if (ax != 0) {
        ax = static_cast<std::uint16_t>(std::uint32_t(ax) * s.si);
        cx = static_cast<std::uint16_t>(ax + cx);
    }
    tmp = ax; ax = s.si; s.si = tmp;
    ax = static_cast<std::uint16_t>(std::uint32_t(ax) * bx);
    dx = static_cast<std::uint16_t>(cx + dx);
    ax = static_cast<std::uint16_t>(ax + 1);
    s.x1a2 = dx; s.words[index] = ax;
    return static_cast<std::uint16_t>(ax ^ dx);
}

std::uint16_t assemble(State& s, const std::uint8_t key[32]) {
    s.words[0] = static_cast<std::uint16_t>((std::uint16_t(key[0]) << 8) | key[1]);
    std::uint16_t inter = code_step(s, 0);
    for (std::uint16_t i = 1; i < 16; ++i) {
        const auto word = static_cast<std::uint16_t>((std::uint16_t(key[2*i]) << 8) | key[2*i+1]);
        s.words[i] = static_cast<std::uint16_t>(s.words[i-1] ^ word);
        inter = static_cast<std::uint16_t>(inter ^ code_step(s, i));
    }
    return inter;
}
}

extern "C" std::int64_t trimaran_enc_pc1(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > max_num_input) return -1;
    constexpr char default_key[] = "abcdefghijklmnopqrstuvwxyz012345";
    std::uint8_t key[32]; for (std::size_t i=0; i<32; ++i) key[i] = static_cast<std::uint8_t>(default_key[i]);
    State state{};
    std::uint32_t seed = 1;
    std::uint16_t last = 0;
    for (std::int64_t step=0; step<input[0]-1; ++step) {
        seed = static_cast<std::uint32_t>(std::uint64_t(seed)*1664525u + 1013904223u);
        const auto plain = static_cast<std::uint16_t>((seed >> 16) & 0x7fff);
        const auto inter = assemble(state, key);
        const auto cipher = static_cast<std::uint16_t>(plain ^ ((inter >> 8) ^ (inter & 255)));
        const auto feedback = static_cast<std::uint8_t>(plain);
        for (auto& byte : key) byte ^= feedback;
        last = cipher;
    }
    return last;
}
