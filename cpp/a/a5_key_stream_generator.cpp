#include <cstddef>
#include <cstdint>

namespace {
struct State { std::uint32_t r1, r2, r3; };
std::uint32_t parity(std::uint32_t x) { x^=x>>16; x^=x>>8; x^=x>>4; x^=x>>2; x^=x>>1; return x&1u; }
std::uint32_t feedback1(const State& s) { return parity(s.r1&((1u<<13)|(1u<<16)|(1u<<17)|(1u<<18))); }
std::uint32_t feedback2(const State& s) { return parity(s.r2&((1u<<20)|(1u<<21))); }
std::uint32_t feedback3(const State& s) { return parity(s.r3&((1u<<7)|(1u<<20)|(1u<<21)|(1u<<22))); }
std::uint32_t push(std::uint32_t r,unsigned n,std::uint32_t b) { return ((r<<1)|b)&((1u<<n)-1u); }
void initialize(State& s,std::uint64_t key,std::uint32_t frame) {
    s={0,0,0};
    for(int i=63;i>=0;--i){auto b=std::uint32_t((key>>i)&1u);s.r1=push(s.r1,19,b^feedback1(s));s.r2=push(s.r2,22,b^feedback2(s));s.r3=push(s.r3,23,b^feedback3(s));}
    for(int i=21;i>=0;--i){auto b=(frame>>i)&1u;s.r1=push(s.r1,19,b^feedback1(s));s.r2=push(s.r2,22,b^feedback2(s));s.r3=push(s.r3,23,b^feedback3(s));}
}
std::uint32_t tick(State& s) {
    const auto c1=(s.r1>>8)&1u,c2=(s.r2>>10)&1u,c3=(s.r3>>10)&1u;
    const auto m=(c1+c2+c3)>=2u; const auto out=((s.r1>>18)^(s.r2>>21)^(s.r3>>22))&1u;
    if(c1==m)s.r1=push(s.r1,19,feedback1(s)); if(c2==m)s.r2=push(s.r2,22,feedback2(s)); if(c3==m)s.r3=push(s.r3,23,feedback3(s));
    return out;
}
std::uint32_t next_frame(std::uint32_t f){for(int i=21;i>=0;--i){auto m=1u<<i;if((f&m)==0)return f|m;f&=~m;}return f;}
}

extern "C" std::int64_t a5_key_stream_generator(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length != 3 || input[2] < 1 || input[2] > 4) return -1;
    const auto blocks = static_cast<std::size_t>(input[2]);
    const auto bytes = 29 * blocks;
    if (output == nullptr || capacity < bytes) return -2;
    const auto key = static_cast<std::uint64_t>(input[0]);
    auto frame = static_cast<std::uint32_t>(static_cast<std::uint64_t>(input[1]) & 0x3fffffu);
    for (std::size_t block = 0; block < blocks; ++block) {
        State state;
        initialize(state, key, frame);
        for (int cycle = 0; cycle < 100; ++cycle) (void)tick(state);
        auto* dst = output + block * 29;
        for (int i = 0; i < 29; ++i) dst[i] = 0;
        for (int bit = 0; bit < 228; ++bit) {
            const auto value = tick(state);
            dst[bit / 8] |= static_cast<std::uint8_t>(value << (bit % 8));
        }
        frame = next_frame(frame);
    }
    return static_cast<std::int64_t>(bytes);
}
