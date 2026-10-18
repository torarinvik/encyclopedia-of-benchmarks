const MAX_INPUT: usize=64;
const MAX_PADDED: usize=128;
const K=[_]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
fn rotr(x:u32,n:u32)u32{const right:u5=@intCast(n);const left:u5=@intCast(32-n);return (x>>right)|(x<<left);}
fn add32(a:u32,b:u32)u32{return @truncate((@as(u64,a)+@as(u64,b))&0xffff_ffff);}

fn lamport_sha256(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(length>MAX_INPUT or (length>0 and input==null))return -1;
    for(0..length)|i|{if(input[i]<0 or input[i]>255)return -1;}
    var padded=[_]u8{0}**MAX_PADDED;
    for(0..length)|i|padded[i]=@intCast(input[i]);
    padded[length]=0x80;
    const blocks=(length+9+63)/64;const padded_length=blocks*64;const bit_length:u64=@as(u64,@intCast(length))*8;
    for(0..8)|i|padded[padded_length-1-i]=@truncate(bit_length>>@intCast(8*i));
    var h=[_]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    for(0..blocks)|block|{
        var w=[_]u32{0}**64;
        for(0..16)|i|{const p=block*64+i*4;w[i]=(@as(u32,padded[p])<<24)|(@as(u32,padded[p+1])<<16)|(@as(u32,padded[p+2])<<8)|padded[p+3];}
        for(16..64)|i|{const x=w[i-15];const y=w[i-2];const s0=rotr(x,7)^rotr(x,18)^(x>>3);const s1=rotr(y,17)^rotr(y,19)^(y>>10);w[i]=add32(add32(add32(s1,w[i-7]),s0),w[i-16]);}
        var a=h[0];var b=h[1];var c=h[2];var d=h[3];var e=h[4];var f=h[5];var g=h[6];var hh=h[7];
        for(0..64)|i|{const s1=rotr(e,6)^rotr(e,11)^rotr(e,25);const ch=(e&f)^((~e)&g);const t1=add32(add32(add32(add32(hh,s1),ch),K[i]),w[i]);const s0=rotr(a,2)^rotr(a,13)^rotr(a,22);const maj=(a&b)^(a&c)^(b&c);const t2=add32(s0,maj);hh=g;g=f;f=e;e=add32(d,t1);d=c;c=b;b=a;a=add32(t1,t2);}
        h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],c);h[3]=add32(h[3],d);h[4]=add32(h[4],e);h[5]=add32(h[5],f);h[6]=add32(h[6],g);h[7]=add32(h[7],hh);
    }
    if(output==null or capacity<32)return -2;
    for(0..8)|i|for(0..4)|byte|output[i*4+byte]=@truncate(h[i]>>@intCast(24-8*byte));
    return 32;
}

const LAMPORT_MAX_MESSAGE: usize = 64;
const LAMPORT_DIGEST_BITS: usize = 256;
const LAMPORT_SECRET_BYTES: usize = 32;
const LAMPORT_ENTROPY_BYTES: usize = LAMPORT_DIGEST_BITS * 2 * LAMPORT_SECRET_BYTES;
const LAMPORT_SIGNATURE_BYTES: usize = LAMPORT_DIGEST_BITS * LAMPORT_SECRET_BYTES;
const LAMPORT_MAX_PARSEABLE: usize = 4 + 2 * LAMPORT_MAX_MESSAGE + LAMPORT_ENTROPY_BYTES + 1;

pub export fn lamport_signature(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 + LAMPORT_ENTROPY_BYTES or length > LAMPORT_MAX_PARSEABLE) return -1;
    if (input[0] < 0 or input[0] > LAMPORT_MAX_MESSAGE) return -1;
    const message_length: usize = @intCast(input[0]);
    const verify_length_index = 1 + message_length;
    if (verify_length_index >= length or input[verify_length_index] < 0 or input[verify_length_index] > LAMPORT_MAX_MESSAGE) return -1;
    const verify_length: usize = @intCast(input[verify_length_index]);
    const verify_start = verify_length_index + 1;
    const verify_end = verify_start + verify_length;
    if (verify_end + 2 > length) return -1;
    const tamper_index = input[verify_end];
    const sign_twice = input[verify_end + 1];
    const entropy_start = verify_end + 2;
    if (length != entropy_start + LAMPORT_ENTROPY_BYTES) return -1;
    if (tamper_index < -1 or tamper_index >= LAMPORT_SIGNATURE_BYTES or (sign_twice != 0 and sign_twice != 1)) return -1;
    for (0..message_length) |i| if (input[1 + i] < 0 or input[1 + i] > 255) return -1;
    for (0..verify_length) |i| if (input[verify_start + i] < 0 or input[verify_start + i] > 255) return -1;
    for (0..LAMPORT_ENTROPY_BYTES) |i| if (input[entropy_start + i] < 0 or input[entropy_start + i] > 255) return -1;

    var public_key: [LAMPORT_DIGEST_BITS][2][32]u8 = undefined;
    var signature: [LAMPORT_SIGNATURE_BYTES]i64 = undefined;
    var message_digest: [32]u8 = undefined;
    for (0..LAMPORT_DIGEST_BITS) |bit| {
        for (0..2) |value| {
            const secret_offset = entropy_start + (bit * 2 + value) * LAMPORT_SECRET_BYTES;
            if (lamport_sha256(&input[secret_offset], LAMPORT_SECRET_BYTES, &public_key[bit][value][0], 32) != 32) return -1;
        }
    }
    if (lamport_sha256(&input[1], message_length, &message_digest[0], 32) != 32) return -1;
    for (0..LAMPORT_DIGEST_BITS) |bit| {
        const value: usize = @intCast((message_digest[bit / 8] >> @intCast(7 - (bit % 8))) & 1);
        const secret_offset = entropy_start + (bit * 2 + value) * LAMPORT_SECRET_BYTES;
        for (0..LAMPORT_SECRET_BYTES) |byte| signature[bit * LAMPORT_SECRET_BYTES + byte] = input[secret_offset + byte];
    }
    if (sign_twice == 1) return -1;

    if (tamper_index >= 0) signature[@intCast(tamper_index)] ^= 1;
    var verify_digest: [32]u8 = undefined;
    if (lamport_sha256(&input[verify_start], verify_length, &verify_digest[0], 32) != 32) return -1;
    var verified: u8 = 1;
    for (0..LAMPORT_DIGEST_BITS) |bit| {
        const value: usize = @intCast((verify_digest[bit / 8] >> @intCast(7 - (bit % 8))) & 1);
        var actual_hash: [32]u8 = undefined;
        if (lamport_sha256(&signature[bit * LAMPORT_SECRET_BYTES], LAMPORT_SECRET_BYTES, &actual_hash[0], 32) != 32) return -1;
        for (0..32) |byte| {
            if (actual_hash[byte] != public_key[bit][value][byte]) { verified = 0; break; }
        }
        if (verified == 0) break;
    }
    if (tamper_index >= 0) signature[@intCast(tamper_index)] ^= 1;

    var fingerprint: u64 = 0xcbf29ce484222325;
    for (0..LAMPORT_DIGEST_BITS) |bit| {
        for (0..2) |value| {
            for (0..32) |byte| fingerprint = (fingerprint ^ public_key[bit][value][byte]) *% 0x100000001b3;
        }
    }
    for (signature) |value| fingerprint = (fingerprint ^ @as(u8, @truncate(@as(u64, @bitCast(value))))) *% 0x100000001b3;
    fingerprint = (fingerprint ^ verified) *% 0x100000001b3;
    return @intCast(fingerprint & 0x7fffffffffffffff);
}
