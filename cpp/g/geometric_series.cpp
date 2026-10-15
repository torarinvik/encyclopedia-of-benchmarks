/* Emit a bounded geometric term sequence as little-endian binary64 values. */
#include <cstddef>
#include <cstdint>
#include <cstring>
static void put_f64_le(std::uint8_t *out, std::size_t offset, double value) noexcept {
    std::uint64_t bits; std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte=0; byte<8; ++byte) out[offset+byte]=static_cast<std::uint8_t>(bits>>(8*byte));
}
extern "C" std::int64_t geometric_series(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity) noexcept {
    if(!input||length!=3||input[0]<0||input[0]>16||input[1]<1||input[1]>8||input[2]<1||input[2]>4)return -1;
    const auto n=static_cast<std::size_t>(input[0]);if(capacity<n*8||(n&& !output))return -2;
    double term=static_cast<double>(input[1]),ratio=static_cast<double>(input[2]);
    for(std::size_t i=0;i<n;++i){put_f64_le(output,i*8,term);term*=ratio;}return static_cast<std::int64_t>(n*8);
}
