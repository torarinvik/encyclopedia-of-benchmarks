const MAX_INPUT: usize = 4096;
const MAX_PADDED: usize = 4160;

fn rol(value: u32, shift: u32) u32 { const left: u5 = @intCast(shift); const right: u5 = @intCast(32 - shift); return (value << left) | (value >> right); }

pub export fn sha1(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (length > MAX_INPUT or (length > 0 and input == null)) return -1;
    for (0..length) |i| { if (input[i] < 0 or input[i] > 255) return -1; }
    var padded = [_]u8{0} ** MAX_PADDED;
    for (0..length) |i| padded[i] = @intCast(input[i]);
    padded[length] = 0x80;
    const blocks = (length + 9 + 63) / 64;
    const padded_length = blocks * 64;
    const bit_length: u64 = @as(u64, @intCast(length)) * 8;
    for (0..8) |i| padded[padded_length - 1 - i] = @truncate(bit_length >> @intCast(8 * i));
    var h0: u32 = 0x67452301; var h1: u32 = 0xEFCDAB89; var h2: u32 = 0x98BADCFE;
    var h3: u32 = 0x10325476; var h4: u32 = 0xC3D2E1F0;
    for (0..blocks) |block| {
        var w = [_]u32{0} ** 80;
        for (0..16) |i| { const p=block*64+i*4; w[i]=(@as(u32,padded[p])<<24)|(@as(u32,padded[p+1])<<16)|(@as(u32,padded[p+2])<<8)|padded[p+3]; }
        for (16..80) |i| w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
        var a=h0; var b=h1; var c=h2; var d=h3; var e=h4;
        for (0..80) |i| {
            var f: u32=0; var k: u32=0;
            if(i<20){f=(b&c)|((~b)&d);k=0x5A827999;}
            else if(i<40){f=b^c^d;k=0x6ED9EBA1;}
            else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8F1BBCDC;}
            else{f=b^c^d;k=0xCA62C1D6;}
            const temp=rol(a,5) +% f +% e +% k +% w[i];
            e=d;d=c;c=rol(b,30);b=a;a=temp;
        }
        h0 +%= a; h1 +%= b; h2 +%= c; h3 +%= d; h4 +%= e;
    }
    if(output==null or capacity<20)return -2;
    const digest=[_]u32{h0,h1,h2,h3,h4};
    for(0..5)|i|for(0..4)|byte|output[i*4+byte]=@truncate(digest[i] >> @intCast(24-8*byte));
    return 20;
}
