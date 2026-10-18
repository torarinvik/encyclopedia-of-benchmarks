#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT=64, MAX_PADDED=128;
constexpr std::uint32_t K[64]={
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
std::uint32_t rotr(std::uint32_t x,unsigned n){return (x>>n)|(x<<(32-n));}
}

static std::int64_t lamport_sha256(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept {
 if(length>MAX_INPUT||(length>0&&input==nullptr))return -1;
 for(std::size_t i=0;i<length;++i)if(input[i]<0||input[i]>255)return -1;
 std::uint8_t padded[MAX_PADDED]{};for(std::size_t i=0;i<length;++i)padded[i]=static_cast<std::uint8_t>(input[i]);padded[length]=0x80;
 const std::size_t blocks=(length+9+63)/64,padded_length=blocks*64;const std::uint64_t bit_length=static_cast<std::uint64_t>(length)*8;
 for(std::size_t i=0;i<8;++i)padded[padded_length-1-i]=static_cast<std::uint8_t>(bit_length>>(8*i));
 std::uint32_t h[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
 for(std::size_t block=0;block<blocks;++block){std::uint32_t w[64];
  for(std::size_t i=0;i<16;++i){const std::size_t p=block*64+i*4;w[i]=(std::uint32_t(padded[p])<<24)|(std::uint32_t(padded[p+1])<<16)|(std::uint32_t(padded[p+2])<<8)|padded[p+3];}
  for(std::size_t i=16;i<64;++i){const std::uint32_t x=w[i-15],y=w[i-2];const std::uint32_t s0=rotr(x,7)^rotr(x,18)^(x>>3),s1=rotr(y,17)^rotr(y,19)^(y>>10);w[i]=s1+w[i-7]+s0+w[i-16];}
  std::uint32_t a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],hh=h[7];
  for(std::size_t i=0;i<64;++i){const std::uint32_t s1=rotr(e,6)^rotr(e,11)^rotr(e,25),ch=(e&f)^(~e&g),t1=hh+s1+ch+K[i]+w[i],s0=rotr(a,2)^rotr(a,13)^rotr(a,22),maj=(a&b)^(a&c)^(b&c),t2=s0+maj;hh=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;}
  h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
 }
 if(output==nullptr||capacity<32)return -2;
 for(std::size_t i=0;i<8;++i)for(std::size_t byte=0;byte<4;++byte)output[i*4+byte]=static_cast<std::uint8_t>(h[i]>>(24-8*byte));
 return 32;
}

#define LAMPORT_MAX_MESSAGE 64u
#define LAMPORT_DIGEST_BITS 256u
#define LAMPORT_SECRET_BYTES 32u
#define LAMPORT_ENTROPY_BYTES (LAMPORT_DIGEST_BITS * 2u * LAMPORT_SECRET_BYTES)
#define LAMPORT_SIGNATURE_BYTES (LAMPORT_DIGEST_BITS * LAMPORT_SECRET_BYTES)
#define LAMPORT_MAX_PARSEABLE (4u + 2u * LAMPORT_MAX_MESSAGE + LAMPORT_ENTROPY_BYTES + 1u)

extern "C" std::int64_t lamport_signature(const std::int64_t *input, std::size_t input_length) noexcept
{
    if (input == NULL || input_length < 4u + LAMPORT_ENTROPY_BYTES || input_length > LAMPORT_MAX_PARSEABLE) return -1;
    if (input[0] < 0 || input[0] > LAMPORT_MAX_MESSAGE) return -1;
    const std::size_t message_length = static_cast<std::size_t>(input[0]);
    const std::size_t verify_length_index = 1u + message_length;
    if (verify_length_index >= input_length || input[verify_length_index] < 0 || input[verify_length_index] > LAMPORT_MAX_MESSAGE) return -1;
    const std::size_t verify_length = static_cast<std::size_t>(input[verify_length_index]);
    const std::size_t verify_start = verify_length_index + 1u;
    const std::size_t verify_end = verify_start + verify_length;
    if (verify_end + 2u > input_length) return -1;
    const std::int64_t tamper_index = input[verify_end];
    const std::int64_t sign_twice = input[verify_end + 1u];
    const std::size_t entropy_start = verify_end + 2u;
    if (input_length != entropy_start + LAMPORT_ENTROPY_BYTES) return -1;
    if (tamper_index < -1 || tamper_index >= LAMPORT_SIGNATURE_BYTES || (sign_twice != 0 && sign_twice != 1)) return -1;
    for (std::size_t i = 0; i < message_length; ++i) if (input[1u + i] < 0 || input[1u + i] > 255) return -1;
    for (std::size_t i = 0; i < verify_length; ++i) if (input[verify_start + i] < 0 || input[verify_start + i] > 255) return -1;
    for (std::size_t i = 0; i < LAMPORT_ENTROPY_BYTES; ++i) if (input[entropy_start + i] < 0 || input[entropy_start + i] > 255) return -1;

    std::uint8_t public_key[LAMPORT_DIGEST_BITS][2][32] = {{{0}}};
    std::int64_t signature[LAMPORT_SIGNATURE_BYTES] = {0};
    std::uint8_t message_digest[32];
    for (std::size_t bit = 0; bit < LAMPORT_DIGEST_BITS; ++bit) {
        for (std::size_t value = 0; value < 2u; ++value) {
            const std::size_t secret_offset = entropy_start + (bit * 2u + value) * LAMPORT_SECRET_BYTES;
            if (lamport_sha256(input + secret_offset, LAMPORT_SECRET_BYTES, public_key[bit][value], 32u) != 32) return -1;
        }
    }
    if (lamport_sha256(input + 1u, message_length, message_digest, 32u) != 32) return -1;
    for (std::size_t bit = 0; bit < LAMPORT_DIGEST_BITS; ++bit) {
        const std::size_t value = (message_digest[bit / 8u] >> (7u - (bit % 8u))) & 1u;
        const std::size_t secret_offset = entropy_start + (bit * 2u + value) * LAMPORT_SECRET_BYTES;
        for (std::size_t byte = 0; byte < LAMPORT_SECRET_BYTES; ++byte) signature[bit * LAMPORT_SECRET_BYTES + byte] = input[secret_offset + byte];
    }
    if (sign_twice == 1) return -1;

    if (tamper_index >= 0) signature[static_cast<std::size_t>(tamper_index)] ^= 1;
    std::uint8_t verify_digest[32];
    if (lamport_sha256(input + verify_start, verify_length, verify_digest, 32u) != 32) return -1;
    std::uint8_t verified = 1u;
    for (std::size_t bit = 0; bit < LAMPORT_DIGEST_BITS; ++bit) {
        const std::size_t value = (verify_digest[bit / 8u] >> (7u - (bit % 8u))) & 1u;
        std::uint8_t actual_hash[32];
        if (lamport_sha256(signature + bit * LAMPORT_SECRET_BYTES, LAMPORT_SECRET_BYTES, actual_hash, 32u) != 32) return -1;
        for (std::size_t byte = 0; byte < 32u; ++byte) {
            if (actual_hash[byte] != public_key[bit][value][byte]) { verified = 0u; break; }
        }
        if (verified == 0u) break;
    }
    if (tamper_index >= 0) signature[static_cast<std::size_t>(tamper_index)] ^= 1;

    std::uint64_t fingerprint = UINT64_C(0xcbf29ce484222325);
    for (std::size_t bit = 0; bit < LAMPORT_DIGEST_BITS; ++bit) {
        for (std::size_t value = 0; value < 2u; ++value) {
            for (std::size_t byte = 0; byte < 32u; ++byte) fingerprint = (fingerprint ^ public_key[bit][value][byte]) * UINT64_C(0x100000001b3);
        }
    }
    for (std::size_t i = 0; i < LAMPORT_SIGNATURE_BYTES; ++i) fingerprint = (fingerprint ^ (std::uint8_t)signature[i]) * UINT64_C(0x100000001b3);
    fingerprint = (fingerprint ^ verified) * UINT64_C(0x100000001b3);
    return static_cast<std::int64_t>(fingerprint & static_cast<std::uint64_t>(INT64_MAX));
}
