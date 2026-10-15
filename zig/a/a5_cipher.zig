const State = struct { r1: u32, r2: u32, r3: u32 };

fn parity(value: u32) u32 {
    var x = value;
    x ^= x >> 16; x ^= x >> 8; x ^= x >> 4; x ^= x >> 2; x ^= x >> 1;
    return x & 1;
}
fn fb1(s: State) u32 { return parity(s.r1 & ((1<<13)|(1<<16)|(1<<17)|(1<<18))); }
fn fb2(s: State) u32 { return parity(s.r2 & ((1<<20)|(1<<21))); }
fn fb3(s: State) u32 { return parity(s.r3 & ((1<<7)|(1<<20)|(1<<21)|(1<<22))); }
fn push(register: u32, width: u5, bit: u32) u32 { return ((register << 1) | bit) & ((@as(u32, 1) << width) - 1); }
fn initialize(key: u64, frame: u32) State {
    var s = State{ .r1 = 0, .r2 = 0, .r3 = 0 };
    var i: i32 = 63;
    while (i >= 0) : (i -= 1) {
        const bit: u32 = @intCast((key >> @intCast(i)) & 1);
        s.r1=push(s.r1,19,bit^fb1(s)); s.r2=push(s.r2,22,bit^fb2(s)); s.r3=push(s.r3,23,bit^fb3(s));
    }
    i = 21;
    while (i >= 0) : (i -= 1) {
        const bit = (frame >> @intCast(i)) & 1;
        s.r1=push(s.r1,19,bit^fb1(s)); s.r2=push(s.r2,22,bit^fb2(s)); s.r3=push(s.r3,23,bit^fb3(s));
    }
    return s;
}
fn tick(s: *State) u32 {
    const c1=(s.r1>>8)&1; const c2=(s.r2>>10)&1; const c3=(s.r3>>10)&1;
    const majority: u32 = @intFromBool(c1+c2+c3>=2);
    const result=((s.r1>>18)^(s.r2>>21)^(s.r3>>22))&1;
    if (c1==majority) s.r1=push(s.r1,19,fb1(s.*));
    if (c2==majority) s.r2=push(s.r2,22,fb2(s.*));
    if (c3==majority) s.r3=push(s.r3,23,fb3(s.*));
    return result;
}
fn nextFrame(frame_in: u32) u32 {
    var frame=frame_in; var i: i32=21;
    while (i>=0) : (i-=1) { const mask: u32=@as(u32,1)<<@intCast(i); if ((frame&mask)==0) return frame|mask; frame &= ~mask; }
    return frame;
}

export fn a5_cipher(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const data=input.?[0..length]; if (data[2]<1 or data[2]>4) return -1;
    const blocks: usize=@intCast(data[2]); if(length!=3+4*blocks)return -1;
    const bytes=32*blocks; if(output==null or capacity<bytes)return -2;
    const dst=output.?[0..bytes]; const key: u64=@bitCast(data[0]); var frame: u32=@truncate(@as(u64,@bitCast(data[1]))&0x3fffff);
    for(0..blocks)|block|{
        var s=initialize(key,frame); for(0..100)|_|{_=tick(&s);}
        @memset(dst[block*32..(block+1)*32],0);
        for(0..228)|bit|{const plain: u64=@bitCast(data[3+4*block+bit/64]);const value: u8=@intCast(((plain>>@intCast(bit%64))&1)^tick(&s));dst[block*32+bit/8]|=value<<@intCast(bit%8);}
        for(228..256)|bit|{const plain: u64=@bitCast(data[3+4*block+bit/64]);const value: u8=@intCast((plain>>@intCast(bit%64))&1);dst[block*32+bit/8]|=value<<@intCast(bit%8);}
        frame=nextFrame(frame);
    }
    return @intCast(bytes);
}
