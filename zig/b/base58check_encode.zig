const MAX_WORDS: usize = 35;
const MAX_PAYLOAD: usize = 32;
const MAX_BASE58: usize = 51;
const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const SHA_K = [_]u32{
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,
    0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,
    0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,
    0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,
    0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
};

fn rotr32(x: u32, n: u32) u32 {
    const right: u5 = @intCast(n);
    const left: u5 = @intCast(32 - n);
    return (x >> right) | (x << left);
}
fn add32(a: u32, b: u32) u32 { return @truncate(@as(u64, a) + @as(u64, b)); }

fn sha256Digest(input: []const u8, digest: *[32]u8) void {
    var block = [_]u8{0} ** 64;
    @memcpy(block[0..input.len], input);
    block[input.len] = 0x80;
    const bit_length: u64 = @as(u64, @intCast(input.len)) * 8;
    for (0..8) |index| block[63 - index] = @truncate(bit_length >> @intCast(8 * index));
    var state = [_]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    var words = [_]u32{0} ** 64;
    for (0..16) |index| {
        const offset = index * 4;
        words[index] = (@as(u32, block[offset]) << 24) | (@as(u32, block[offset + 1]) << 16) |
            (@as(u32, block[offset + 2]) << 8) | block[offset + 3];
    }
    for (16..64) |index| {
        const x=words[index-15];const y=words[index-2];
        const small0=rotr32(x,7)^rotr32(x,18)^(x>>3);
        const small1=rotr32(y,17)^rotr32(y,19)^(y>>10);
        words[index]=add32(add32(add32(small1,words[index-7]),small0),words[index-16]);
    }
    var a=state[0];var b=state[1];var c=state[2];var d=state[3];
    var e=state[4];var f=state[5];var g=state[6];var h=state[7];
    for (0..64) |index| {
        const big1=rotr32(e,6)^rotr32(e,11)^rotr32(e,25);
        const choose=(e&f)^((~e)&g);
        const first=add32(add32(add32(add32(h,big1),choose),SHA_K[index]),words[index]);
        const big0=rotr32(a,2)^rotr32(a,13)^rotr32(a,22);
        const majority=(a&b)^(a&c)^(b&c);
        const second=add32(big0,majority);
        h=g;g=f;f=e;e=add32(d,first);d=c;c=b;b=a;a=add32(first,second);
    }
    state[0]=add32(state[0],a);state[1]=add32(state[1],b);state[2]=add32(state[2],c);state[3]=add32(state[3],d);
    state[4]=add32(state[4],e);state[5]=add32(state[5],f);state[6]=add32(state[6],g);state[7]=add32(state[7],h);
    for (0..8) |index| for (0..4) |byte|
        digest[index * 4 + byte] = @truncate(state[index] >> @intCast(24 - 8 * byte));
}

pub export fn base58check_encode(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_WORDS) return -1;
    const version = values[0];
    const payload_value = values[1];
    if (version < 0 or version > 255 or payload_value < 0 or payload_value > 32) return -1;
    const payload_length: usize = @intCast(payload_value);
    if (length != payload_length + 2) return -1;

    var message = [_]u8{0} ** (MAX_PAYLOAD + 1);
    var raw = [_]u8{0} ** (MAX_PAYLOAD + 5);
    message[0] = @intCast(version);
    raw[0] = @intCast(version);
    for (0..payload_length) |index| {
        const byte = values[index + 2];
        if (byte < 0 or byte > 255) return -1;
        message[index + 1] = @intCast(byte);
        raw[index + 1] = @intCast(byte);
    }
    const message_length = payload_length + 1;
    var digest_one: [32]u8 = undefined;
    sha256Digest(message[0..message_length], &digest_one);
    var digest_two: [32]u8 = undefined;
    sha256Digest(digest_one[0..], &digest_two);

    const raw_length = message_length + 4;
    @memcpy(raw[message_length..raw_length], digest_two[0..4]);
    var leading_zeroes: usize = 0;
    while (leading_zeroes < raw_length and raw[leading_zeroes] == 0) : (leading_zeroes += 1) {}
    var digits = [_]u8{0} ** MAX_BASE58;
    var digit_count: usize = 0;
    for (raw[leading_zeroes..raw_length]) |byte| {
        var carry: u32 = byte;
        for (0..digit_count) |digit| {
            carry += @as(u32, digits[digit]) * 256;
            digits[digit] = @intCast(carry % 58);
            carry /= 58;
        }
        while (carry != 0) {
            digits[digit_count] = @intCast(carry % 58);
            digit_count += 1;
            carry /= 58;
        }
    }
    const encoded_length = leading_zeroes + digit_count;
    if (output == null or output_capacity < encoded_length) return -2;
    var written: usize = 0;
    while (written < leading_zeroes) : (written += 1) output[written] = '1';
    while (digit_count > 0) {
        digit_count -= 1;
        output[written] = ALPHABET[digits[digit_count]];
        written += 1;
    }
    return @intCast(encoded_length);
}
