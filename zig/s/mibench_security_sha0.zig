const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;
const MAX_MESSAGE_BYTES: usize = 55;

fn rol32(value: u32, shift: u5) u32 {
    const inverse: u5 = @intCast(32 - @as(u32, shift));
    return (value << shift) | (value >> inverse);
}
fn transform_sha0(block: *const [64]u8, state: *[5]u32) void {
    var words = [_]u32{0} ** 80;
    for (0..16) |i| {
        const p=i*4;
        words[i]=(@as(u32,block[p])<<24)|(@as(u32,block[p+1])<<16)|(@as(u32,block[p+2])<<8)|block[p+3];
    }
    for (16..80) |i| words[i]=words[i-3]^words[i-8]^words[i-14]^words[i-16];
    var a=state[0]; var b=state[1]; var c=state[2]; var d=state[3]; var e=state[4];
    for (0..80) |i| {
        var f:u32=0; var k:u32=0;
        if(i<20){f=(b&c)|((~b)&d);k=0x5A827999;}
        else if(i<40){f=b^c^d;k=0x6ED9EBA1;}
        else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8F1BBCDC;}
        else{f=b^c^d;k=0xCA62C1D6;}
        const temp=rol32(a,5)+%f+%e+%words[i]+%k;
        e=d;d=c;c=rol32(b,30);b=a;a=temp;
    }
    state[0]+%=a;state[1]+%=b;state[2]+%=c;state[3]+%=d;state[4]+%=e;
}

export fn mibench_security_sha0(input: [*c]const i64, input_length: usize,
        output: [*c]u8, output_capacity: usize) i64 {
    if(input==null or input_length<1 or input_length>MAX_MESSAGE_BYTES+2)return INVALID_RESULT;
    const message_length=input[0];
    if(message_length<0 or message_length>@as(i64,@intCast(MAX_MESSAGE_BYTES)) or input_length!=@as(usize,@intCast(message_length))+1)return INVALID_RESULT;
    for (1..input_length) |i| {
        if (input[i] < 0 or input[i] > 255) return INVALID_RESULT;
    }
    var block=[_]u8{0}**64;
    for (0..@intCast(message_length)) |i| {
        block[i] = @intCast(input[i + 1]);
    }
    block[@intCast(message_length)]=0x80;
    const bit_length=@as(u64,@intCast(message_length))*8;
    for (0..8) |i| {
        block[63 - i] = @truncate(bit_length >> @intCast(8 * i));
    }
    var state=[_]u32{0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0};
    transform_sha0(&block,&state);
    if(output==null or output_capacity<20)return OUTPUT_ERROR;
    for (0..5) |i| {
        for (0..4) |j| {
            output[i * 4 + j] = @truncate(state[i] >> @intCast(24 - 8 * j));
        }
    }
    return 20;
}
