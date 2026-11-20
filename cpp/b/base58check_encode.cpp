#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_WORDS = 35;
constexpr std::size_t MAX_PAYLOAD = 32;
constexpr std::size_t MAX_RAW = 37;
constexpr std::size_t MAX_BASE58 = 51;
constexpr char ALPHABET[] = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
constexpr std::uint32_t SHA_K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

std::uint32_t rotr32(std::uint32_t value, unsigned amount)
{
    return (value >> amount) | (value << (32 - amount));
}

void sha256_digest(const std::uint8_t *input, std::size_t length, std::uint8_t output[32])
{
    std::uint8_t block[64]{};
    std::uint32_t state[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
                            0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    std::uint32_t words[64];
    for (std::size_t index=0; index<length; ++index) block[index]=input[index];
    block[length]=0x80;
    const std::uint64_t bit_length=static_cast<std::uint64_t>(length)*8;
    for (std::size_t index=0; index<8; ++index)
        block[63-index]=static_cast<std::uint8_t>(bit_length>>(8*index));
    for (std::size_t index=0; index<16; ++index) {
        const std::size_t offset=index*4;
        words[index]=(std::uint32_t(block[offset])<<24)|(std::uint32_t(block[offset+1])<<16)|
                     (std::uint32_t(block[offset+2])<<8)|block[offset+3];
    }
    for (std::size_t index=16; index<64; ++index) {
        const std::uint32_t x=words[index-15], y=words[index-2];
        const std::uint32_t small0=rotr32(x,7)^rotr32(x,18)^(x>>3);
        const std::uint32_t small1=rotr32(y,17)^rotr32(y,19)^(y>>10);
        words[index]=small1+words[index-7]+small0+words[index-16];
    }
    std::uint32_t a=state[0],b=state[1],c=state[2],d=state[3];
    std::uint32_t e=state[4],f=state[5],g=state[6],h=state[7];
    for (std::size_t index=0; index<64; ++index) {
        const std::uint32_t big1=rotr32(e,6)^rotr32(e,11)^rotr32(e,25);
        const std::uint32_t choose=(e&f)^(~e&g);
        const std::uint32_t first=h+big1+choose+SHA_K[index]+words[index];
        const std::uint32_t big0=rotr32(a,2)^rotr32(a,13)^rotr32(a,22);
        const std::uint32_t majority=(a&b)^(a&c)^(b&c);
        const std::uint32_t second=big0+majority;
        h=g;g=f;f=e;e=d+first;d=c;c=b;b=a;a=first+second;
    }
    state[0]+=a;state[1]+=b;state[2]+=c;state[3]+=d;
    state[4]+=e;state[5]+=f;state[6]+=g;state[7]+=h;
    for (std::size_t word=0; word<8; ++word)
        for (std::size_t byte=0; byte<4; ++byte)
            output[word*4+byte]=static_cast<std::uint8_t>(state[word]>>(24-8*byte));
}
}

extern "C" std::int64_t base58check_encode(const std::int64_t *values,
                                            std::size_t length,
                                            std::uint8_t *output,
                                            std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > MAX_WORDS) return -1;
    const std::int64_t version = values[0];
    const std::int64_t payload_length_value = values[1];
    if (version < 0 || version > 255 || payload_length_value < 0 ||
        payload_length_value > static_cast<std::int64_t>(MAX_PAYLOAD)) return -1;
    const std::size_t payload_length = static_cast<std::size_t>(payload_length_value);
    if (length != payload_length + 2) return -1;

    std::uint8_t message[MAX_PAYLOAD + 1]{};
    std::uint8_t first_digest[32]{}, second_digest[32]{}, raw[MAX_RAW]{};
    message[0] = static_cast<std::uint8_t>(version);
    raw[0] = static_cast<std::uint8_t>(version);
    for (std::size_t index = 0; index < payload_length; ++index) {
        const std::int64_t byte = values[index + 2];
        if (byte < 0 || byte > 255) return -1;
        message[index + 1] = static_cast<std::uint8_t>(byte);
        raw[index + 1] = static_cast<std::uint8_t>(byte);
    }
    const std::size_t message_length = payload_length + 1;
    sha256_digest(message, message_length, first_digest);
    sha256_digest(first_digest, sizeof first_digest, second_digest);

    const std::size_t raw_length = message_length + 4;
    for (std::size_t index = 0; index < 4; ++index)
        raw[message_length + index] = second_digest[index];
    std::size_t leading_zeroes = 0;
    while (leading_zeroes < raw_length && raw[leading_zeroes] == 0) ++leading_zeroes;

    std::uint8_t digits[MAX_BASE58]{};
    std::size_t digit_count = 0;
    for (std::size_t index = leading_zeroes; index < raw_length; ++index) {
        unsigned carry = raw[index];
        for (std::size_t digit = 0; digit < digit_count; ++digit) {
            carry += static_cast<unsigned>(digits[digit]) * 256;
            digits[digit] = static_cast<std::uint8_t>(carry % 58);
            carry /= 58;
        }
        while (carry != 0) {
            digits[digit_count++] = static_cast<std::uint8_t>(carry % 58);
            carry /= 58;
        }
    }
    const std::size_t encoded_length = leading_zeroes + digit_count;
    if (output == nullptr || output_capacity < encoded_length) return -2;
    std::size_t written = 0;
    while (written < leading_zeroes) output[written++] = static_cast<std::uint8_t>('1');
    while (digit_count != 0) {
        --digit_count;
        output[written++] = static_cast<std::uint8_t>(ALPHABET[digits[digit_count]]);
    }
    return static_cast<std::int64_t>(encoded_length);
}
