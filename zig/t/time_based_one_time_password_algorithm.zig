const MAX_KEY: usize = 64;
const MAX_WORDS: usize = 67;

fn rol(x: u32, n: u5) u32 { const r: u5 = @intCast(32 - @as(u32,n)); return (x << n) | (x >> r); }

fn compress(h: *[5]u32, block: *const [64]u8) void {
    var w = [_]u32{0} ** 80;
    for (0..16) |i| { const j=4*i;w[i]=(@as(u32,block[j])<<24)|(@as(u32,block[j+1])<<16)|(@as(u32,block[j+2])<<8)|block[j+3]; }
    for (16..80) |i| w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
    var a=h[0];var b=h[1];var c=h[2];var d=h[3];var e=h[4];
    for (0..80) |i| {
        var f:u32=undefined;var k:u32=undefined;
        if(i<20){f=(b&c)|(~b&d);k=0x5a827999;}else if(i<40){f=b^c^d;k=0x6ed9eba1;}else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8f1bbcdc;}else{f=b^c^d;k=0xca62c1d6;}
        const t=rol(a,5)+%f+%e+%k+%w[i];e=d;d=c;c=rol(b,30);b=a;a=t;
    }
    h[0]+%=a;h[1]+%=b;h[2]+%=c;h[3]+%=d;h[4]+%=e;
}

fn initial() [5]u32 { return .{0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0}; }
fn serialize(h: *const [5]u32, out: *[20]u8) void { for(0..5)|i|{out[4*i]=@truncate(h[i]>>24);out[4*i+1]=@truncate(h[i]>>16);out[4*i+2]=@truncate(h[i]>>8);out[4*i+3]=@truncate(h[i]);} }

fn compute(input: [*]const i64, key_len: usize, out: *[6]u8) void {
    var key=[_]u8{0}**64;var block=[_]u8{0}**64;var inner=[_]u8{0}**20;
    for(0..key_len)|i|key[i]=@intCast(input[i+1]);for(0..64)|i|block[i]=key[i]^0x36;
    var h=initial();compress(&h,&block);@memset(block[0..],0);
    const counter=@as(u64,@intCast(input[key_len+1]))/30;for(0..8)|i|block[i]=@truncate(counter>>(56-8*i));block[8]=0x80;block[62]=2;block[63]=0x40;
    compress(&h,&block);serialize(&h,&inner);for(0..64)|i|block[i]=key[i]^0x5c;
    h=initial();compress(&h,&block);@memset(block[0..],0);@memcpy(block[0..20],inner[0..]);block[20]=0x80;block[62]=2;block[63]=0xa0;
    compress(&h,&block);serialize(&h,&inner);const off:usize=@intCast(inner[19]&15);
    var binary=(@as(u32,inner[off])<<24)|(@as(u32,inner[off+1])<<16)|(@as(u32,inner[off+2])<<8)|inner[off+3];binary&=0x7fffffff;
    var value=binary%1_000_000;var i:usize=6;while(i>0){i-=1;out[i]='0'+@as(u8,@intCast(value%10));value/=10;}
}

pub export fn time_based_one_time_password_algorithm(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values=input orelse return -1;if(length<3 or length>MAX_WORDS)return -1;const kw=values[0];if(kw<16 or kw>@as(i64,@intCast(MAX_KEY)) or length!=@as(usize,@intCast(kw))+2)return -1;
    const key_len:usize=@intCast(kw);for(0..key_len)|i|if(values[i+1]<0 or values[i+1]>255)return -1;
    if(values[key_len+1]<0)return -1;var staged=[_]u8{0}**6;compute(values,key_len,&staged);
    const dest=output orelse return -2;if(capacity<6)return -2;@memcpy(dest[0..6],staged[0..]);return 6;
}
