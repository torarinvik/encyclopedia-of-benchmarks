fn put(out:[*c]u8,x:i64)void{const bits:u64=@bitCast(x);for(0..8)|b|out[b]=@truncate(bits>>@intCast(b*8));}
pub export fn ams_sketch(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<4 or length>116)return -1;
    const d0=input[0];const w0=input[1];const k0=input[2];const u0=input[3];
    if((d0!=1 and d0!=3 and d0!=5)or w0<1 or w0>8 or k0<1 or k0>8 or u0<0 or u0>16)return -1;
    const d:usize=@intCast(d0);const w:usize=@intCast(w0);const k:usize=@intCast(k0);const u:usize=@intCast(u0);const start=4+2*d*k;if(length!=start+2*u)return -1;
    for(0..d)|r|{for(0..k)|key|{const p=4+2*(r*k+key);if(input[p]<0 or input[p]>=w0 or (input[p+1]!=-1 and input[p+1]!=1))return -1;}}
    for(0..u)|i|{const key=input[start+2*i];const weight=input[start+2*i+1];if(key<0 or key>=k0 or weight< -1000 or weight>1000)return -1;}
    var counters = [_][8]i64{[_]i64{0} ** 8} ** 5;
    var estimates = [_]i64{0} ** 5;
    for(0..u)|i|{const key:usize=@intCast(input[start+2*i]);const weight=input[start+2*i+1];for(0..d)|r|{const p=4+2*(r*k+key);const bucket:usize=@intCast(input[p]);const sign=input[p+1];counters[r][bucket]+=weight*sign;}}
    for(0..d)|r|{for(0..w)|b|{estimates[r]+=counters[r][b]*counters[r][b];}}
    for(1..d)|i|{const x=estimates[i];var j=i;while(j>0 and estimates[j-1]>x):(j-=1){estimates[j]=estimates[j-1];}estimates[j]=x;}
    if(capacity<8 or output==null)return -2;put(output,estimates[d/2]);return 8;
}
