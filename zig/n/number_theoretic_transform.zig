// New bounded port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt.
const MODULUS: i64 = 998244353;
fn modPow(a_value: i64, exponent_value: i64) i64 { var a=a_value; var exponent=exponent_value; var result:i64=1; while (exponent>0) : (exponent >>= 1) { if ((exponent & 1)!=0) result=@mod(result*a,MODULUS); a=@mod(a*a,MODULUS); } return result; }

pub export fn number_theoretic_transform(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    const input=values orelse return -1;
    if (length<2 or length>65) return -1;
    const n0=input[0];
    if (n0<1 or n0>64 or (n0 & (n0-1))!=0 or length!=@as(usize,@intCast(n0))+1) return -1;
    const n:usize=@intCast(n0); var a:[64]i64=@splat(0);
    for (0..n) |i| { const value=input[i+1]; if (value<0 or value>=MODULUS) return -1; a[i]=value; }
    const out=output orelse return -2;
    if (output_capacity<4*n) return -2;
    var j:usize=0;
    for (1..n) |i| { var bit=n>>1; while ((j & bit)!=0) { j^=bit; bit>>=1; } j^=bit; if (i<j) { const temp=a[i]; a[i]=a[j]; a[j]=temp; } }
    var len:usize=2;
    while (len<=n) : (len*=2) {
        const step=modPow(3,(MODULUS-1)/@as(i64,@intCast(len)));
        var base:usize=0;
        while (base<n) : (base+=len) { var w:i64=1; for (0..len/2) |k| { const u=a[base+k]; const v=@mod(a[base+k+len/2]*w,MODULUS); a[base+k]=@mod(u+v,MODULUS); a[base+k+len/2]=@mod(u-v+MODULUS,MODULUS); w=@mod(w*step,MODULUS); } }
    }
    for (0..n) |i| { const x:u32=@intCast(a[i]); for (0..4) |b| { out[4*i+b]=@truncate(x >> @intCast(8*b)); } }
    return @intCast(4*n);
}
