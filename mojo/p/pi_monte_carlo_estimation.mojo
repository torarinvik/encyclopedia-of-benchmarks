from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MT_A:UInt32=0x9908B0DF
fn mt_twist(mut s:InlineArray[UInt32,624]):
    for i in range(227):
        let y=(s[i]&0x80000000)|(s[i+1]&0x7fffffff);s[i]=s[i+397]^(y>>1);if (y&1)!=0:s[i]^=MT_A
    for i in range(227,623):
        let y=(s[i]&0x80000000)|(s[i+1]&0x7fffffff);s[i]=s[i-227]^(y>>1);if (y&1)!=0:s[i]^=MT_A
    let y=(s[623]&0x80000000)|(s[0]&0x7fffffff);s[623]=s[396]^(y>>1);if (y&1)!=0:s[623]^=MT_A
fn mt_u32(mut s:InlineArray[UInt32,624],mut ix:Int)->UInt32:
    if ix>=624:mt_twist(mut s);ix=0
    var y=s[ix];ix+=1;y^=y>>11;y^=(y<<7)&0x9D2C5680;y^=(y<<15)&0xEFC60000;y^=y>>18
    return y
fn mt_random(mut s:InlineArray[UInt32,624],mut ix:Int)->Float64:
    let high=mt_u32(mut s,mut ix)>>5;let low=mt_u32(mut s,mut ix)>>6
    return (Float64(high)*67108864.0+Float64(low))*(1.0/9007199254740992.0)
@export("pi_monte_carlo_estimation")
fn pi_monte_carlo_estimation(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=2 or not is_finite(v[0]) or not is_finite(v[1]):return -1
    let sims=Int(v[0]);let seed=Int64(v[1]);if v[0]!=Float64(sims) or sims<1 or sims>100000 or v[1]!=Float64(seed) or seed<0 or seed>4294967295:return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    var s=InlineArray[UInt32,624](fill=0);s[0]=19650218
    for i in range(1,624):let prev=s[i-1];s[i]=1812433253*(prev^(prev>>30))+UInt32(i)
    var ix=1
    for _ in range(624):let prev=s[ix-1];s[ix]=(s[ix]^((prev^(prev>>30))*1664525))+UInt32(seed);ix+=1;if ix>=624:s[0]=s[623];ix=1
    for _ in range(623):let prev=s[ix-1];s[ix]=(s[ix]^((prev^(prev>>30))*1566083941))-UInt32(ix);ix+=1;if ix>=624:s[0]=s[623];ix=1
    s[0]=0x80000000;var random_index=624;var hits=0
    for _ in range(sims):let x=mt_random(mut s,mut random_index);let y=mt_random(mut s,mut random_index);if x*x+y*y<=1.0:hits+=1
    o[0]=Float64(4*hits)/Float64(sims);return 1
