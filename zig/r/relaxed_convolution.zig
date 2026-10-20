// New bounded relaxed-convolution schedule; see benchmarks/r/relaxed_convolution/README.md and LICENSE.txt.
const MODULUS:i64=998244353;
pub export fn relaxed_convolution(values:?[*]const i64,length:usize,output:?[*]u8,output_capacity:usize)i64{
    const input=values orelse return -1;if(length<3 or length>33)return -1;const n0=input[0];if(n0<1 or n0>16 or length!=1+2*@as(usize,@intCast(n0)))return -1;
    const n:usize=@intCast(n0);var a:[16]i64=@splat(0);var b:[16]i64=@splat(0);var c:[16]i64=@splat(0);
    for(0..n)|i|{a[i]=input[1+i];b[i]=input[1+n+i];if(a[i]<0 or a[i]>=MODULUS or b[i]<0 or b[i]>=MODULUS)return -1;}
    const out=output orelse return -2;if(output_capacity<4*n)return -2;
    for(0..n)|index|{var value=a[index]*b[0];if(index>0)value+=b[index]*a[0];c[index]=@mod(c[index]+value,MODULUS);const q=index+1;var d:usize=1;
        while(d<=q):(d*=2){if(q%(2*d)==d){const end=@min(q+d,n);if(q==d){for(q..end)|i|{const target=d+i-q;for(0..d)|r|{const y=target-r;if(y<d)c[i]=@mod(c[i]+a[r]*b[y],MODULUS);}}}else{for(q..end)|i|{const target=d+i-q;for(0..d)|r|{const y=target-r;if(y<2*d)c[i]=@mod(c[i]+a[q-d+r]*b[y]+b[q-d+r]*a[y],MODULUS);}}}}}
    }
    for(0..n)|i|{const x:u32=@intCast(c[i]);for(0..4)|j|{out[4*i+j]=@truncate(x>>@intCast(8*j));}}return @intCast(4*n);
}
