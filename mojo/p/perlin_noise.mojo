from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime JAVA_MUL:UInt64=0x5DEECE66D
comptime JAVA_ADD:UInt64=0xB
comptime JAVA_MASK:UInt64=0xFFFFFFFFFFFF
fn pl_next(mut state:UInt64,bits:Int)->UInt32:
    state=(state*JAVA_MUL+JAVA_ADD)&JAVA_MASK
    return UInt32(state>>(48-bits))
fn pl_interpolate(a:Float32,b:Float32,alpha:Float32)->Float32:
    let om=Float32(1.0)-alpha;let left=a*om;let right=alpha*b
    return left+right
@export("perlin_noise")
fn perlin_noise(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<4 or n>6 or n!=5:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let width=Int(v[0]);let height=Int(v[1]);let oct=Int(v[2]);let seed=Int64(v[4])
    if v[0]!=Float64(width) or v[1]!=Float64(height) or v[2]!=Float64(oct) or width<1 or width>8 or height<1 or height>8 or oct<1 or oct>4 or (v[3]!=0.5 and v[3]!=0.75 and v[3]!=1.0) or v[4]!=Float64(seed) or seed<0 or seed>2147483647:return -1
    let count=width*height;var base=InlineArray[Float32,64](fill=0.0);var layers=InlineArray[Float32,256](fill=0.0);var result=InlineArray[Float32,64](fill=0.0)
    var state=(UInt64(seed)^JAVA_MUL)&JAVA_MASK
    for x in range(width):for y in range(height):base[x*height+y]=Float32(pl_next(mut state,24))/Float32(16777216.0)
    for octave in range(oct):
        let period=1<<octave;let frequency=Float32(1.0)/Float32(period)
        for x in range(width):
            let x0=(x/period)*period;let x1=(x0+period)%width;let horizontal=Float32(x-x0)*frequency
            for y in range(height):
                let y0=(y/period)*period;let y1=(y0+period)%height;let vertical=Float32(y-y0)*frequency
                let top=pl_interpolate(base[x0*height+y0],base[x1*height+y0],horizontal)
                let bottom=pl_interpolate(base[x0*height+y1],base[x1*height+y1],horizontal)
                layers[octave*64+x*height+y]=pl_interpolate(top,bottom,vertical)
    var amplitude:Float32=1.0;var total:Float32=0.0;let persistence=Float32(v[3])
    for rev in range(oct):
        let octave=oct-1-rev;amplitude*=persistence;total+=amplitude
        for i in range(count):result[i]+=layers[octave*64+i]*amplitude
    let inverse=Float32(1.0)/total
    for i in range(count):result[i]*=inverse
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):o[i]=Float64(result[i])
    return Int64(count)
