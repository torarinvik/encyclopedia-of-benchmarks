// Clean-room TSVC s1111 profile; see package rights note.
const MAX_N:usize=32;const MAX_INPUT_LENGTH:usize=161;
fn put64(out:[*]u8,pos:usize,v:i64)void{const bits=@as(u64,@bitCast(v));for(0..8)|j|out[pos+j]=@truncate(bits>>(8*j));}
pub export fn tsvc_s1111_stride_two_polynomial_map(input:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64{
 if(input==null or length<6 or length>MAX_INPUT_LENGTH)return -1;const v=input.?[0..length];if(v[0]<1 or v[0]>MAX_N)return -1;const n:usize=@intCast(v[0]);if(length!=1+5*n)return -1;
 var a=[_]i64{0}**64;var b=[_]i64{0}**32;var c=[_]i64{0}**32;var d=[_]i64{0}**32;var off:usize=1;for(0..2*n)|i|{const x=v[off+i];if(x< -2 or x>2)return -1;a[i]=x;}off+=2*n;
 for(0..n)|i|{const x=v[off+i];if(x< -2 or x>2)return -1;b[i]=x;}off+=n;for(0..n)|i|{const x=v[off+i];if(x< -2 or x>2)return -1;c[i]=x;}off+=n;for(0..n)|i|{const x=v[off+i];if(x< -2 or x>2)return -1;d[i]=x;}
 const bytes=16*n;if(output==null or capacity<bytes)return -2;for(0..n)|i|a[2*i]=c[i]*b[i]+d[i]*b[i]+c[i]*c[i]+d[i]*b[i]+d[i]*c[i];for(0..2*n)|i|put64(output.?,8*i,a[i]);return @intCast(2*n);
}
