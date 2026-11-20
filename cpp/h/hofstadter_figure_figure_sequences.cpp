#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_terms = 64;
constexpr std::size_t max_words = 1 + 2 * max_terms;

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte=0; byte<8; ++byte) output[offset+byte] = static_cast<std::uint8_t>(bits>>(byte*8));
}
}

extern "C" std::int64_t hofstadter_figure_figure_sequences(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input==nullptr || length==0 || length>2) return -1;
    if (input[0]<1 || input[0]>static_cast<std::int64_t>(max_terms) || length!=1) return -1;
    const auto n=static_cast<std::size_t>(input[0]);
    std::array<std::int64_t,max_terms> figure{}, space{};
    figure[0]=1; space[0]=2;
    std::int64_t candidate=3;
    for (std::size_t i=1;i<n;++i) {
        figure[i]=figure[i-1]+space[i-1];
        for (;;) {
            bool used=false;
            for (std::size_t j=0;j<=i;++j) if (figure[j]==candidate) used=true;
            if (!used) break;
            ++candidate;
        }
        space[i]=candidate++;
    }
    const auto count=1+2*n, bytes=count*8;
    if (output==nullptr || capacity<bytes) return -2;
    std::array<std::int64_t,max_words> words{};
    words[0]=static_cast<std::int64_t>(n);
    for (std::size_t i=0;i<n;++i) { words[1+i]=figure[i]; words[1+n+i]=space[i]; }
    for (std::size_t i=0;i<count;++i) write_i64_le(output,i*8,words[i]);
    return static_cast<std::int64_t>(bytes);
}
