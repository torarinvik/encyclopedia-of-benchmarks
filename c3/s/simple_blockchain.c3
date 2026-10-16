module simple_blockchain;

const uint[64] K={
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
const usz MAX_INPUT=4096, MAX_PADDED=4160;
fn uint rotr(uint x,uint n){return (x>>n)|(x<<(32-n));}
fn long bc_sha256(long* input,usz length,char* output,usz capacity) {
    if(length>MAX_INPUT||(length>0&&input==null))return -1;
    for(usz i=0;i<length;i++)if(input[i]<0||input[i]>255)return -1;
    u8[MAX_PADDED] padded;for(usz i=0;i<MAX_PADDED;i++)padded[i]=0;
    for(usz i=0;i<length;i++)padded[i]=(u8)input[i];padded[length]=0x80;
    usz blocks=(length+9+63)/64,padded_length=blocks*64;ulong bit_length=(ulong)length*8;
    for(usz i=0;i<8;i++)padded[padded_length-1-i]=(u8)(bit_length>>(8*i));
    uint[8] h={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    for(usz block=0;block<blocks;block++){
        uint[64] w;
        for(usz i=0;i<16;i++){usz p=block*64+i*4;w[i]=((uint)padded[p]<<24)|((uint)padded[p+1]<<16)|((uint)padded[p+2]<<8)|(uint)padded[p+3];}
        for(usz i=16;i<64;i++){uint x=w[i-15],y=w[i-2];uint s0=rotr(x,7)^rotr(x,18)^(x>>3),s1=rotr(y,17)^rotr(y,19)^(y>>10);w[i]=s1+w[i-7]+s0+w[i-16];}
        uint a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],hh=h[7];
        for(usz i=0;i<64;i++){
            uint s1=rotr(e,6)^rotr(e,11)^rotr(e,25),ch=(e&f)^(~e&g),t1=hh+s1+ch+K[i]+w[i];
            uint s0=rotr(a,2)^rotr(a,13)^rotr(a,22),maj=(a&b)^(a&c)^(b&c),t2=s0+maj;
            hh=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;
        }
        h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
    }
    if(output==null||capacity<32)return -2;
    for(usz i=0;i<8;i++)for(usz byte=0;byte<4;byte++)output[i*4+byte]=(char)(h[i]>>(24-8*byte));
    return 32;
}


const usz BC_MAX_VALUES = 465;
const usz BC_MAX_CHAIN = 8;
const usz BC_MAX_DATA = 64;
const usz BC_MAX_HEADER = 160;
const long BC_NONCE_ATTEMPTS = 4096;
const usz BC_MAX_OUTPUT = 728;

fn usz bc_append_decimal(long* buffer, usz position, long value) {
    long digits[20];
    usz count = 0;
    do {
        digits[count++] = '0' + value % 10;
        value /= 10;
    } while (value != 0);
    while (count != 0) buffer[position++] = digits[--count];
    return position;
}

fn usz bc_make_header(usz index, long timestamp_sec, char* data, usz data_length,
                      char* previous_hash, usz previous_hash_length, long nonce,
                      long* header) {
    usz length = 0;
    length = bc_append_decimal(header, length, (long)index);
    length = bc_append_decimal(header, length, timestamp_sec);
    header[length++] = '.';
    header[length++] = '0';
    for (usz i = 0; i < data_length; i++) header[length++] = (u8)data[i];
    for (usz i = 0; i < previous_hash_length; i++) header[length++] = (u8)previous_hash[i];
    return bc_append_decimal(header, length, nonce);
}

fn bool bc_compute_hash(usz index, long timestamp_sec, char* data, usz data_length,
                        char* previous_hash, usz previous_hash_length, long nonce,
                        char* output) {
    long header[BC_MAX_HEADER];
    char digest[32];
    usz length = bc_make_header(index, timestamp_sec, data, data_length,
                                previous_hash, previous_hash_length, nonce, header);
    if (bc_sha256(header, length, digest, 32) != 32) return false;
    const char* hex = "0123456789abcdef";
    for (usz i = 0; i < 32; i++) {
        u8 byte = (u8)digest[i];
        output[2 * i] = hex[byte >> 4];
        output[2 * i + 1] = hex[byte & 15];
    }
    return true;
}

fn bool bc_has_prefix(char* hash, long difficulty) {
    for (long i = 0; i < difficulty; i++) if (hash[i] != '0') return false;
    return true;
}

fn bool bc_is_valid(long* timestamps, long* data_lengths, char* data, char* previous_hash,
                    usz* previous_lengths, long* nonces, char* hashes,
                    usz chain_length, long difficulty) {
    for (usz i = 1; i < chain_length; i++) {
        char recomputed[64];
        if (previous_lengths[i] != 64) return false;
        for (usz j = 0; j < 64; j++)
            if (previous_hash[i * 64 + j] != hashes[(i - 1) * 64 + j]) return false;
        if (!bc_has_prefix(&hashes[i * 64], difficulty)) return false;
        if (!bc_compute_hash(i, timestamps[i], &data[i * BC_MAX_DATA], (usz)data_lengths[i],
                             &previous_hash[i * 64], previous_lengths[i], nonces[i], recomputed))
            return false;
        for (usz j = 0; j < 64; j++)
            if (hashes[i * 64 + j] != recomputed[j]) return false;
    }
    return true;
}

fn usz bc_write_i64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) output[position++] = (char)(bits >> (8 * i));
    return position;
}

fn long simple_blockchain(long* input, usz length, char* output, usz output_capacity)
        @export("simple_blockchain") {
    if (input == null || length < 3 || length > BC_MAX_VALUES) return -1;
    long difficulty = input[0];
    long chain_length_value = input[1];
    if (difficulty < 1 || difficulty > 2 || chain_length_value < 1 || chain_length_value > 8) return -1;
    usz chain_length = (usz)chain_length_value;
    long max_timestamp = 2147483647;
    if (input[2] < 0 || input[2] > max_timestamp) return -1;

    long timestamps[BC_MAX_CHAIN];
    long data_lengths[BC_MAX_CHAIN];
    long nonces[BC_MAX_CHAIN];
    usz previous_lengths[BC_MAX_CHAIN];
    char data[BC_MAX_CHAIN * BC_MAX_DATA];
    char previous_hash[BC_MAX_CHAIN * 64];
    char hashes[BC_MAX_CHAIN * 64];
    for (usz i = 0; i < BC_MAX_CHAIN; i++) {
        timestamps[i] = 0; data_lengths[i] = 0; nonces[i] = 0; previous_lengths[i] = 0;
    }
    timestamps[0] = input[2];
    const long genesis[13] = {71,101,110,101,115,105,115,32,66,108,111,99,107};
    for (usz i = 0; i < 13; i++) data[i] = (char)genesis[i];
    data_lengths[0] = 13;
    previous_hash[0] = '0';
    previous_lengths[0] = 1;

    usz cursor = 3;
    for (usz i = 1; i < chain_length; i++) {
        if (cursor + 2 > length) return -1;
        long timestamp_sec = input[cursor++];
        long data_length_value = input[cursor++];
        if (timestamp_sec < 0 || timestamp_sec > max_timestamp || data_length_value < 0 || data_length_value > 64)
            return -1;
        usz data_length = (usz)data_length_value;
        if (cursor + data_length > length) return -1;
        timestamps[i] = timestamp_sec;
        data_lengths[i] = data_length_value;
        for (usz j = 0; j < data_length; j++) {
            if (input[cursor + j] < 0 || input[cursor + j] > 127) return -1;
            data[i * BC_MAX_DATA + j] = (char)input[cursor + j];
        }
        cursor += data_length;
    }
    if (cursor != length) return -1;

    for (usz i = 0; i < chain_length; i++) {
        if (i > 0) {
            for (usz j = 0; j < 64; j++) previous_hash[i * 64 + j] = hashes[(i - 1) * 64 + j];
            previous_lengths[i] = 64;
        }
        bool mined = false;
        for (long nonce = 0; nonce < BC_NONCE_ATTEMPTS; nonce++) {
            char candidate[64];
            if (!bc_compute_hash(i, timestamps[i], &data[i * BC_MAX_DATA], (usz)data_lengths[i],
                                 &previous_hash[i * 64], previous_lengths[i], nonce, candidate))
                return -1;
            if (bc_has_prefix(candidate, difficulty)) {
                nonces[i] = nonce;
                for (usz j = 0; j < 64; j++) hashes[i * 64 + j] = candidate[j];
                mined = true;
                break;
            }
        }
        if (!mined) return -3;
    }

    long valid = bc_is_valid(timestamps, data_lengths, data, previous_hash, previous_lengths,
                             nonces, hashes, chain_length, difficulty) ? 1 : 0;
    char payload[BC_MAX_OUTPUT];
    usz written = 0;
    written = bc_write_i64(payload, written, 0);
    written = bc_write_i64(payload, written, chain_length_value);
    for (usz i = 0; i < chain_length; i++) {
        written = bc_write_i64(payload, written, (long)i);
        written = bc_write_i64(payload, written, timestamps[i]);
        written = bc_write_i64(payload, written, nonces[i]);
        for (usz j = 0; j < 64; j++) payload[written++] = hashes[i * 64 + j];
    }
    written = bc_write_i64(payload, written, valid);
    if (output == null || output_capacity < written) return -2;
    for (usz i = 0; i < written; i++) output[i] = payload[i];
    return (long)written;
}
