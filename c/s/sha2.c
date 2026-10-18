#include <stddef.h>
#include <stdint.h>

enum { MAX_MESSAGE_BYTES = 4096, MAX_PARSEABLE_INPUT_LENGTH = 4099, MAX_PADDED_BYTES = 4224, MAX_OUTPUT_BYTES = 64 };

static const uint32_t K32[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static const uint64_t K64[80] = {
    UINT64_C(0x428a2f98d728ae22),UINT64_C(0x7137449123ef65cd),UINT64_C(0xb5c0fbcfec4d3b2f),UINT64_C(0xe9b5dba58189dbbc),
    UINT64_C(0x3956c25bf348b538),UINT64_C(0x59f111f1b605d019),UINT64_C(0x923f82a4af194f9b),UINT64_C(0xab1c5ed5da6d8118),
    UINT64_C(0xd807aa98a3030242),UINT64_C(0x12835b0145706fbe),UINT64_C(0x243185be4ee4b28c),UINT64_C(0x550c7dc3d5ffb4e2),
    UINT64_C(0x72be5d74f27b896f),UINT64_C(0x80deb1fe3b1696b1),UINT64_C(0x9bdc06a725c71235),UINT64_C(0xc19bf174cf692694),
    UINT64_C(0xe49b69c19ef14ad2),UINT64_C(0xefbe4786384f25e3),UINT64_C(0x0fc19dc68b8cd5b5),UINT64_C(0x240ca1cc77ac9c65),
    UINT64_C(0x2de92c6f592b0275),UINT64_C(0x4a7484aa6ea6e483),UINT64_C(0x5cb0a9dcbd41fbd4),UINT64_C(0x76f988da831153b5),
    UINT64_C(0x983e5152ee66dfab),UINT64_C(0xa831c66d2db43210),UINT64_C(0xb00327c898fb213f),UINT64_C(0xbf597fc7beef0ee4),
    UINT64_C(0xc6e00bf33da88fc2),UINT64_C(0xd5a79147930aa725),UINT64_C(0x06ca6351e003826f),UINT64_C(0x142929670a0e6e70),
    UINT64_C(0x27b70a8546d22ffc),UINT64_C(0x2e1b21385c26c926),UINT64_C(0x4d2c6dfc5ac42aed),UINT64_C(0x53380d139d95b3df),
    UINT64_C(0x650a73548baf63de),UINT64_C(0x766a0abb3c77b2a8),UINT64_C(0x81c2c92e47edaee6),UINT64_C(0x92722c851482353b),
    UINT64_C(0xa2bfe8a14cf10364),UINT64_C(0xa81a664bbc423001),UINT64_C(0xc24b8b70d0f89791),UINT64_C(0xc76c51a30654be30),
    UINT64_C(0xd192e819d6ef5218),UINT64_C(0xd69906245565a910),UINT64_C(0xf40e35855771202a),UINT64_C(0x106aa07032bbd1b8),
    UINT64_C(0x19a4c116b8d2d0c8),UINT64_C(0x1e376c085141ab53),UINT64_C(0x2748774cdf8eeb99),UINT64_C(0x34b0bcb5e19b48a8),
    UINT64_C(0x391c0cb3c5c95a63),UINT64_C(0x4ed8aa4ae3418acb),UINT64_C(0x5b9cca4f7763e373),UINT64_C(0x682e6ff3d6b2b8a3),
    UINT64_C(0x748f82ee5defb2fc),UINT64_C(0x78a5636f43172f60),UINT64_C(0x84c87814a1f0ab72),UINT64_C(0x8cc702081a6439ec),
    UINT64_C(0x90befffa23631e28),UINT64_C(0xa4506cebde82bde9),UINT64_C(0xbef9a3f7b2c67915),UINT64_C(0xc67178f2e372532b),
    UINT64_C(0xca273eceea26619c),UINT64_C(0xd186b8c721c0c207),UINT64_C(0xeada7dd6cde0eb1e),UINT64_C(0xf57d4f7fee6ed178),
    UINT64_C(0x06f067aa72176fba),UINT64_C(0x0a637dc5a2c898a6),UINT64_C(0x113f9804bef90dae),UINT64_C(0x1b710b35131c471b),
    UINT64_C(0x28db77f523047d84),UINT64_C(0x32caab7b40c72493),UINT64_C(0x3c9ebe0a15c9bebc),UINT64_C(0x431d67c49c100d4c),
    UINT64_C(0x4cc5d4becb3e42b6),UINT64_C(0x597f299cfc657e2a),UINT64_C(0x5fcb6fab3ad6faec),UINT64_C(0x6c44198c4a475817)
};

static const uint32_t H224[8] = {0xc1059ed8,0x367cd507,0x3070dd17,0xf70e5939,0xffc00b31,0x68581511,0x64f98fa7,0xbefa4fa4};
static const uint32_t H256[8] = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
static const uint64_t H384[8] = {UINT64_C(0xcbbb9d5dc1059ed8),UINT64_C(0x629a292a367cd507),UINT64_C(0x9159015a3070dd17),UINT64_C(0x152fecd8f70e5939),UINT64_C(0x67332667ffc00b31),UINT64_C(0x8eb44a8768581511),UINT64_C(0xdb0c2e0d64f98fa7),UINT64_C(0x47b5481dbefa4fa4)};
static const uint64_t H512[8] = {UINT64_C(0x6a09e667f3bcc908),UINT64_C(0xbb67ae8584caa73b),UINT64_C(0x3c6ef372fe94f82b),UINT64_C(0xa54ff53a5f1d36f1),UINT64_C(0x510e527fade682d1),UINT64_C(0x9b05688c2b3e6c1f),UINT64_C(0x1f83d9abfb41bd6b),UINT64_C(0x5be0cd19137e2179)};
static const uint64_t H512_224[8] = {UINT64_C(0x8c3d37c819544da2),UINT64_C(0x73e1996689dcd4d6),UINT64_C(0x1dfab7ae32ff9c82),UINT64_C(0x679dd514582f9fcf),UINT64_C(0x0f6d2b697bd44da8),UINT64_C(0x77e36f7304c48942),UINT64_C(0x3f9d85a86a1d36c8),UINT64_C(0x1112e6ad91d692a1)};
static const uint64_t H512_256[8] = {UINT64_C(0x22312194fc2bf72c),UINT64_C(0x9f555fa3c84c64c2),UINT64_C(0x2393b86b6f53b151),UINT64_C(0x963877195940eabd),UINT64_C(0x96283ee2a88effe3),UINT64_C(0xbe5e1e2553863992),UINT64_C(0x2b0199fc2c85b8aa),UINT64_C(0x0eb72ddc81c52ca2)};

static uint32_t rotate_right32(uint32_t value, unsigned amount) { return (value >> amount) | (value << (32 - amount)); }
static uint64_t rotate_right64(uint64_t value, unsigned amount) { return (value >> amount) | (value << (64 - amount)); }

static void compress32(uint32_t state[8], const uint8_t block[64])
{
    uint32_t words[64];
    for (size_t index = 0; index < 16; ++index) {
        const size_t offset = index * 4;
        words[index] = ((uint32_t)block[offset] << 24) | ((uint32_t)block[offset + 1] << 16) |
            ((uint32_t)block[offset + 2] << 8) | (uint32_t)block[offset + 3];
    }
    for (size_t index = 16; index < 64; ++index) {
        const uint32_t x = words[index - 15], y = words[index - 2];
        const uint32_t s0 = rotate_right32(x, 7) ^ rotate_right32(x, 18) ^ (x >> 3);
        const uint32_t s1 = rotate_right32(y, 17) ^ rotate_right32(y, 19) ^ (y >> 10);
        words[index] = words[index - 16] + s0 + words[index - 7] + s1;
    }
    uint32_t a=state[0],b=state[1],c=state[2],d=state[3],e=state[4],f=state[5],g=state[6],h=state[7];
    for (size_t index = 0; index < 64; ++index) {
        const uint32_t sigma1=rotate_right32(e,6)^rotate_right32(e,11)^rotate_right32(e,25);
        const uint32_t choose=(e&f)^((~e)&g);
        const uint32_t temp1=h+sigma1+choose+K32[index]+words[index];
        const uint32_t sigma0=rotate_right32(a,2)^rotate_right32(a,13)^rotate_right32(a,22);
        const uint32_t majority=(a&b)^(a&c)^(b&c);
        const uint32_t temp2=sigma0+majority;
        h=g;g=f;f=e;e=d+temp1;d=c;c=b;b=a;a=temp1+temp2;
    }
    state[0]+=a;state[1]+=b;state[2]+=c;state[3]+=d;state[4]+=e;state[5]+=f;state[6]+=g;state[7]+=h;
}

static void compress64(uint64_t state[8], const uint8_t block[128])
{
    uint64_t words[80];
    for (size_t index = 0; index < 16; ++index) {
        uint64_t value = 0;
        for (size_t byte = 0; byte < 8; ++byte) value = (value << 8) | block[index * 8 + byte];
        words[index] = value;
    }
    for (size_t index = 16; index < 80; ++index) {
        const uint64_t x=words[index-15],y=words[index-2];
        const uint64_t s0=rotate_right64(x,1)^rotate_right64(x,8)^(x>>7);
        const uint64_t s1=rotate_right64(y,19)^rotate_right64(y,61)^(y>>6);
        words[index]=words[index-16]+s0+words[index-7]+s1;
    }
    uint64_t a=state[0],b=state[1],c=state[2],d=state[3],e=state[4],f=state[5],g=state[6],h=state[7];
    for (size_t index = 0; index < 80; ++index) {
        const uint64_t sigma1=rotate_right64(e,14)^rotate_right64(e,18)^rotate_right64(e,41);
        const uint64_t choose=(e&f)^((~e)&g);
        const uint64_t temp1=h+sigma1+choose+K64[index]+words[index];
        const uint64_t sigma0=rotate_right64(a,28)^rotate_right64(a,34)^rotate_right64(a,39);
        const uint64_t majority=(a&b)^(a&c)^(b&c);
        const uint64_t temp2=sigma0+majority;
        h=g;g=f;f=e;e=d+temp1;d=c;c=b;b=a;a=temp1+temp2;
    }
    state[0]+=a;state[1]+=b;state[2]+=c;state[3]+=d;state[4]+=e;state[5]+=f;state[6]+=g;state[7]+=h;
}

int64_t sha2(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > 5 || values[1] < 0 || values[1] > MAX_MESSAGE_BYTES) return -1;
    const size_t variant = (size_t)values[0], message_length = (size_t)values[1];
    if (length != 2 + message_length) return -1;
    for (size_t index = 0; index < message_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 255) return -1;

    static const size_t digest_lengths[6] = {28,32,48,64,28,32};
    const size_t digest_length = digest_lengths[variant];
    if (output == NULL || output_capacity < digest_length) return -2;

    uint8_t padded[MAX_PADDED_BYTES] = {0};
    for (size_t index = 0; index < message_length; ++index) padded[index] = (uint8_t)values[2 + index];
    padded[message_length] = 0x80;
    if (variant < 2) {
        size_t padded_length = message_length + 1;
        while (padded_length % 64 != 56) ++padded_length;
        padded_length += 8;
        const uint64_t bit_length = (uint64_t)message_length * 8;
        for (size_t byte = 0; byte < 8; ++byte) padded[padded_length - 1 - byte] = (uint8_t)(bit_length >> (8 * byte));
        uint32_t state[8];
        const uint32_t *initial = variant == 0 ? H224 : H256;
        for (size_t index = 0; index < 8; ++index) state[index] = initial[index];
        for (size_t offset = 0; offset < padded_length; offset += 64) compress32(state, &padded[offset]);
        size_t output_index = 0;
        for (size_t word = 0; word < 8 && output_index < digest_length; ++word)
            for (size_t byte = 0; byte < 4 && output_index < digest_length; ++byte)
                output[output_index++] = (uint8_t)(state[word] >> (24 - 8 * byte));
    } else {
        size_t padded_length = message_length + 1;
        while (padded_length % 128 != 112) ++padded_length;
        padded_length += 16;
        const uint64_t bit_length = (uint64_t)message_length * 8;
        for (size_t byte = 0; byte < 8; ++byte) padded[padded_length - 1 - byte] = (uint8_t)(bit_length >> (8 * byte));
        const uint64_t *initial = variant == 2 ? H384 : variant == 3 ? H512 : variant == 4 ? H512_224 : H512_256;
        uint64_t state[8];
        for (size_t index = 0; index < 8; ++index) state[index] = initial[index];
        for (size_t offset = 0; offset < padded_length; offset += 128) compress64(state, &padded[offset]);
        size_t output_index = 0;
        for (size_t word = 0; word < 8 && output_index < digest_length; ++word)
            for (size_t byte = 0; byte < 8 && output_index < digest_length; ++byte)
                output[output_index++] = (uint8_t)(state[word] >> (56 - 8 * byte));
    }
    return (int64_t)digest_length;
}
