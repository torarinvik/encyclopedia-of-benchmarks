const MAX_INPUT: usize=8192;
const MAX_PADDED: usize=8256;
const K=[_]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
fn rotr(x:u32,n:u32)u32{const right:u5=@intCast(n);const left:u5=@intCast(32-n);return (x>>right)|(x<<left);}
fn add32(a:u32,b:u32)u32{return @truncate((@as(u64,a)+@as(u64,b))&0xffff_ffff);}

pub export fn sha256(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
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


fn verifySignature(input:[*]const i64,height:usize,w:usize,msg:usize,leaf_index:usize,sig_pos:usize,pk_pos:usize,auth_pos:usize,root_pos:usize,l:usize)i64{
    var digest=[_]u8{0}**32;var current=[_]u8{0}**32;if(sha256(input+3,msg,&digest[0],32)!=32)return 0;
    const log_w:usize=if(w==4)2 else if(w==16)4 else 8;const len1:usize=if(w==4)128 else if(w==16)64 else 32;const len2=l-len1;const mask=w-1;
    var digits=[_]u8{0}**133;var d:usize=0;var checksum:i32=0;
    for(0..32)|byte|{for(0..8/log_w)|part|{const shift=8-log_w*(part+1);digits[d]=@intCast((digest[byte]>>@intCast(shift))&@as(u8,@intCast(mask)));checksum+=@as(i32,@intCast(mask))-@as(i32,digits[d]);d+=1;}}
    for(0..len2)|i|{digits[len1+len2-1-i]=@intCast(@as(usize,@intCast(checksum))&mask);checksum >>= @intCast(log_w);}
    var chain=[_]i64{0}**32;for(0..l)|i|{for(0..32)|j|chain[j]=input[sig_pos+32*i+j];var step:usize=0;while(step<w-1-digits[i]):(step+=1){if(sha256(&chain[0],32,&current[0],32)!=32)return 0;for(0..32)|j|chain[j]=current[j];}for(0..32)|j|{if(@as(u8,@intCast(chain[j]))!=@as(u8,@intCast(input[pk_pos+32*i+j])))return 0;}}
    if(sha256(input+pk_pos,32*l,&digest[0],32)!=32)return 0;var pair=[_]i64{0}**64;var index=leaf_index;for(0..height)|level|{for(0..32)|j|{const left:i64=digest[j];const right=input[auth_pos+32*level+j];if(index%2==0){pair[j]=left;pair[32+j]=right;}else{pair[j]=right;pair[32+j]=left;}}if(sha256(&pair[0],64,&digest[0],32)!=32)return 0;index >>= 1;}for(0..32)|j|{if(digest[j]!=@as(u8,@intCast(input[root_pos+j])))return 0;}return 1;
}
pub export fn merkle_signature_scheme(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<4 or length>8932)return -1;const h0=input[0];const w0=input[1];const m0=input[2];if(h0<2 or h0>10 or (w0!=4 and w0!=16 and w0!=256) or m0<0 or m0>64)return -1;
    const height:usize=@intCast(h0);const w:usize=@intCast(w0);const msg:usize=@intCast(m0);const l:usize=if(w==4)133 else if(w==16)67 else 34;const ip=3+msg;const expected=4+msg+64*l+32*height+32;if(length!=expected)return -1;
    for(0..msg)|i|{if(input[3+i]<0 or input[3+i]>127)return -1;}const index0=input[ip];if(index0<0 or @as(u64,@intCast(index0))>=(@as(u64,1)<<@intCast(height)))return -1;
    const sig=ip+1;const pk=sig+32*l;const auth=pk+32*l;const root=auth+32*height;for(sig..length)|i|{if(input[i]<0 or input[i]>255)return -1;}if(output==null or capacity<8)return -2;
    const valid=verifySignature(input,height,w,msg,@intCast(index0),sig,pk,auth,root,l);for(0..8)|i|output[i]=0;output[0]=@intCast(valid);return 8;
}
