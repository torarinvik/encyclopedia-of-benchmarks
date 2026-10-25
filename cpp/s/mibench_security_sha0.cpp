#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
constexpr std::size_t max_message_bytes = 55;

std::uint32_t rol32(std::uint32_t value, unsigned shift) {
    return (value << shift) | (value >> (32u - shift));
}

void transform_sha0(const std::uint8_t (&block)[64], std::uint32_t (&state)[5]) {
    std::uint32_t words[80]{};
    for (std::size_t i = 0; i < 16; ++i) {
        const auto p = i * 4;
        words[i] = (std::uint32_t(block[p]) << 24) | (std::uint32_t(block[p + 1]) << 16) |
                   (std::uint32_t(block[p + 2]) << 8) | block[p + 3];
    }
    for (std::size_t i = 16; i < 80; ++i)
        words[i] = words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16];

    auto a=state[0], b=state[1], c=state[2], d=state[3], e=state[4];
    for (std::size_t i = 0; i < 80; ++i) {
        std::uint32_t f, k;
        if (i < 20) { f=(b&c)|(~b&d); k=0x5A827999u; }
        else if (i < 40) { f=b^c^d; k=0x6ED9EBA1u; }
        else if (i < 60) { f=(b&c)|(b&d)|(c&d); k=0x8F1BBCDCu; }
        else { f=b^c^d; k=0xCA62C1D6u; }
        const std::uint32_t temporary=rol32(a,5)+f+e+words[i]+k;
        e=d; d=c; c=rol32(b,30); b=a; a=temporary;
    }
    state[0]+=a; state[1]+=b; state[2]+=c; state[3]+=d; state[4]+=e;
}
}

extern "C" std::int64_t mibench_security_sha0(const std::int64_t *input,
        std::size_t input_length, std::uint8_t *output, std::size_t output_capacity) {
    if (input==nullptr || input_length<1 || input_length>max_message_bytes+2) return invalid_result;
    const auto message_length=input[0];
    if (message_length<0 || message_length>static_cast<std::int64_t>(max_message_bytes) ||
        input_length!=static_cast<std::size_t>(message_length)+1) return invalid_result;
    for (std::size_t i=1;i<input_length;++i) if(input[i]<0 || input[i]>255) return invalid_result;
    std::uint8_t block[64]{};
    for (std::size_t i=0;i<static_cast<std::size_t>(message_length);++i) block[i]=static_cast<std::uint8_t>(input[i+1]);
    block[static_cast<std::size_t>(message_length)]=0x80;
    const std::uint64_t bit_length=static_cast<std::uint64_t>(message_length)*8u;
    for (std::size_t i=0;i<8;++i) block[63-i]=static_cast<std::uint8_t>(bit_length>>(8*i));
    std::uint32_t state[5]={0x67452301u,0xEFCDAB89u,0x98BADCFEu,0x10325476u,0xC3D2E1F0u};
    transform_sha0(block,state);
    if (output==nullptr || output_capacity<20) return output_error;
    for (std::size_t i=0;i<5;++i) for (std::size_t j=0;j<4;++j)
        output[i*4+j]=static_cast<std::uint8_t>(state[i]>>(24-8*j));
    return 20;
}
