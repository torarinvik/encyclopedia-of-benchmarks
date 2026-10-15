fn symbolValue(value: i64) ?i32 {
    var code = value;
    if (code >= 'a' and code <= 'z') code -= 'a' - 'A';
    if (code >= 'A' and code <= 'Z') return @intCast(code - 'A');
    if (code >= '0' and code <= '9') return @as(i32, @intCast(code - '0')) + 26;
    return null;
}
fn outputSymbol(value: i32) u8 { return if (value < 26) @intCast('A' + value) else @intCast('0' + value - 26); }

pub export fn hill_cipher_mod36(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or input[0] < 0 or input[0] > 1) return -1;
    const raw_length=input[1];if(raw_length<1 or raw_length>256 or length!=@as(usize,@intCast(raw_length))+2)return -1;
    var text:[256]i32=undefined;var count:usize=0;
    for(0..@intCast(raw_length))|i|{const byte=input[2+i];if(byte<0 or byte>127)return -1;if(symbolValue(byte))|value|{text[count]=value;count+=1;}}
    if(count==0)return -1;if(count%2!=0){text[count]=text[count-1];count+=1;}
    if(output==null or capacity<count)return -2;const decrypt=input[0]==1;
    for(0..count)|i|{if(i%2!=0)continue;const a=text[i];const b=text[i+1];const first=if(decrypt)@mod(6*a+25*b,36)else @mod(2*a+5*b,36);const second=if(decrypt)@mod(5*a+26*b,36)else @mod(a+6*b,36);output[i]=outputSymbol(first);output[i+1]=outputSymbol(second);}
    return @intCast(count);
}
