const MaxK:usize=3;const MaxP:usize=32;const MaxInput:usize=70;const MaxOutput:usize=256;
fn isPrime(p:usize)bool{if(p<2)return false;var d:usize=2;while(d*d<=p):(d+=1){if(p%d==0)return false;}return true;}
fn storeLe(output:[*]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|output[offset+b]=@truncate(bits>>@intCast(8*b));}
export fn multivariate_convolution_cyclic(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<2 or length>MaxInput)return -1;const input=input_opt.?;const p0=input[0];const k0=input[1];if(p0<2 or p0>97 or !isPrime(@intCast(p0)) or k0<0 or k0>3)return -1;const p:usize=@intCast(p0);const k:usize=@intCast(k0);if(length<2+k)return -1;
    var dims:[MaxK]usize=@splat(0);var product:usize=1;for(0..k)|axis|{const d0=input[2+axis];if(d0<2 or d0>32)return -1;const d:usize=@intCast(d0);if((p-1)%d!=0 or product>MaxP/d)return -1;dims[axis]=d;product*=d;}
    const start=2+k;if(length!=start+2*product)return -1;for(input[start..length])|x|{if(x<0 or x>=p0)return -1;}
    const bytes=8*product;if(bytes>MaxOutput)return -1;if(output_opt==null or capacity<bytes)return -2;var a:[MaxP]i64=@splat(0);var b:[MaxP]i64=@splat(0);var result:[MaxP]i64=@splat(0);
    for(0..product)|i|{a[i]=input[start+i];b[i]=input[start+product+i];}
    for(0..product)|i|{for(0..product)|j|{var target:usize=0;var stride:usize=1;for(0..k)|axis|{const d=dims[axis];const sum=((i/stride)%d+(j/stride)%d)%d;target+=sum*stride;stride*=d;}result[target]=(result[target]+a[i]*b[j])%p0;}}
    const output=output_opt.?;for(0..product)|i|storeLe(output,8*i,result[i]);return @intCast(bytes);
}
