/* Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
 * Apache-2.0 licensed upstream kernel, bounded variant; modifications made. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TEXT = 96;
void scan_text(const std::uint8_t *text, std::size_t n, std::uint32_t *finals,
               std::uint32_t *transitions) {
    std::size_t pos = 0;
    while (pos < n) {
        unsigned state = 0;
        while (pos < n && state != 1) {
            const auto ch = text[pos];
            if (ch == ',') { ++pos; break; }
            const bool digit = ch >= '0' && ch <= '9';
            switch (state) {
            case 0: if (digit) state=4; else if(ch=='+'||ch=='-') state=2; else if(ch=='.') state=5; else {state=1; ++transitions[1];} ++transitions[0]; break;
            case 2: if(digit) state=4; else if(ch=='.') state=5; else state=1; ++transitions[2]; break;
            case 4: if(ch=='.'){state=5;++transitions[4];} else if(!digit){state=1;++transitions[4];} break;
            case 5: if(ch=='e'||ch=='E'){state=3;++transitions[5];} else if(!digit){state=1;++transitions[5];} break;
            case 3: if(ch=='+'||ch=='-') state=6; else state=1; ++transitions[3]; break;
            case 6: if(digit) state=7; else state=1; ++transitions[6]; break;
            case 7: if(!digit){state=1;++transitions[1];} break;
            }
            ++pos;
        }
        ++finals[state];
    }
}
void put_u32(std::uint8_t *out, std::size_t at, std::uint32_t x) {
    for (std::size_t b=0;b<4;++b) out[at+b]=static_cast<std::uint8_t>(x>>(8*b));
}
}

extern "C" std::int64_t numeric_token_state_machine(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length<4 || length>MAX_TEXT+3) return -1;
    const auto raw_n=input[0], step=input[1], seed=input[2];
    if(raw_n<1||raw_n>static_cast<std::int64_t>(MAX_TEXT)||length!=static_cast<std::size_t>(raw_n+3)||step<1||step>16||seed<1||seed>255) return -1;
    const auto n=static_cast<std::size_t>(raw_n);
    std::uint8_t text[MAX_TEXT]{};
    for(std::size_t i=0;i<n;++i){if(input[3+i]<32||input[3+i]>126)return -1;text[i]=static_cast<std::uint8_t>(input[3+i]);}
    if(text[0]==','||text[n-1]==',')return -1;
    for(std::size_t i=1;i<n;++i)if(text[i]==','&&text[i-1]==',')return -1;
    for(std::size_t i=0;i<n;i+=static_cast<std::size_t>(step))if(text[i]!=','&&(static_cast<std::uint8_t>(text[i]^seed)==','||static_cast<std::uint8_t>(text[i]^seed)==0))return -1;
    std::uint32_t finals[8]{}, transitions[8]{};
    scan_text(text,n,finals,transitions);
    for(std::size_t i=0;i<n;i+=static_cast<std::size_t>(step))if(text[i]!=',')text[i]^=static_cast<std::uint8_t>(seed);
    scan_text(text,n,finals,transitions);
    for(std::size_t i=0;i<n;i+=static_cast<std::size_t>(step))if(text[i]!=',')text[i]^=static_cast<std::uint8_t>(seed);
    if(!output||capacity<64)return -2;
    for(std::size_t i=0;i<8;++i){put_u32(output,8*i,finals[i]);put_u32(output,8*i+4,transitions[i]);}
    return 64;
}
