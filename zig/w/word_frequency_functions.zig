const MAX_TERM: usize = 128;
const MAX_TEXT: usize = 4096;
const MAX_PACKED: usize = 4227;
const MAX_COUNT: i64 = 1_000_000;

fn punct(c: u8) bool { return (c >= 33 and c <= 47) or (c >= 58 and c <= 64) or (c >= 91 and c <= 96) or (c >= 123 and c <= 126); }
fn lowerAscii(c: u8) u8 { return if (c >= 65 and c <= 90) c + 32 else c; }
fn put32(out: [*]u8, pos: *usize, value: u32) void { var bits=value;for(0..4)|_|{out[pos.*]=@truncate(bits);pos.*+=1;bits>>=8;} }
fn put64(out: [*]u8, pos: *usize, value: i64) void { var bits: u64=@bitCast(value);for(0..8)|_|{out[pos.*]=@truncate(bits);pos.*+=1;bits>>=8;} }
fn milli(x: f64) i64 {
    const y=x*1000.0;const lo=@floor(y);const frac=y-lo;
    if(frac<0.5)return @intFromFloat(lo);
    if(frac>0.5)return @intFromFloat(lo+1.0);
    const k: i64=@intFromFloat(lo);return if(@mod(k,2)==0) k else k+1;
}

export fn word_frequency_functions(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if(input==null or length<1 or length>MAX_PACKED)return -1;
    const v=input.?;const op=v[0];var kind:i64=0;var a:i64=0;var b:i64=0;var out_len:usize=12;
    if(op==0 or op==1){
        if(length<3 or v[1]<0 or v[1]>@as(i64,@intCast(MAX_TERM)))return -1;
        const tn:usize=@intCast(v[1]);const ti=2+tn;
        if(length<ti+1 or v[ti]<0 or v[ti]>@as(i64,@intCast(MAX_TEXT)))return -1;
        const dn:usize=@intCast(v[ti]);const di=ti+1;if(length!=di+dn)return -1;
        var term:[MAX_TERM]u8=@splat(0);var text:[MAX_TEXT]u8=@splat(0);var clean:[MAX_TEXT]u8=@splat(0);
        for(0..tn)|i|{const x=v[2+i];if(x<0 or x>127)return -1;term[i]=lowerAscii(@intCast(x));}
        for(0..dn)|i|{const x=v[di+i];if(x<0 or x>127)return -1;text[i]=@intCast(x);}
        var cn:usize=0;for(0..dn)|i|{if(!punct(text[i]) and (op!=0 or text[i]!=10)){clean[cn]=if(op==1)lowerAscii(text[i])else text[i];cn+=1;}}
        if(op==0){
            var start:usize=0;for(0..cn+1)|i|{if(i==cn or clean[i]==32){const n=i-start;var same=n==tn;for(0..n)|j|{if(same and lowerAscii(clean[start+j])!=term[j])same=false;}if(same)a+=1;start=i+1;}}
        }else{
            kind=1;out_len=20;var start:usize=0;for(0..cn+1)|i|{if(i==cn or clean[i]==10){const n=i-start;var found=tn==0;var j:usize=0;while(!found and j+tn<=n):(j+=1){var k:usize=0;while(k<tn and clean[start+j+k]==term[k]){k+=1;}if(k==tn)found=true;}if(found)a+=1;b+=1;start=i+1;}}
        }
    }else if(op==2){
        if(length!=4)return -1;const df=v[1];const n=v[2];const smooth=v[3];
        if(df<0 or df>MAX_COUNT or n<0 or n>MAX_COUNT or (smooth!=0 and smooth!=1))return -1;
        if(smooth==1 and n==0){kind=4;out_len=4;}else if(smooth==0 and df==0){kind=3;out_len=4;}else if(smooth==0 and n==0){kind=4;out_len=4;}else{
            const nf:f64=@floatFromInt(n);const dff:f64=@floatFromInt(df);const value=if(smooth==1) 1.0+@log10(nf/@as(f64,@floatFromInt(1+df))) else @log10(nf/dff);
            kind=2;a=milli(value);
        }
    }else if(op==3){
        if(length!=3 or v[1]<0 or v[1]>MAX_COUNT or v[2]<-MAX_COUNT or v[2]>MAX_COUNT)return -1;
        kind=2;a=v[1]*v[2];
    }else return -1;
    if(output==null or capacity<out_len)return -2;const out=output.?;var pos:usize=0;put32(out,&pos,@intCast(kind));
    if(kind==0 or kind==2)put64(out,&pos,a) else if(kind==1){put64(out,&pos,a);put64(out,&pos,b);}
    return @intCast(pos);
}
