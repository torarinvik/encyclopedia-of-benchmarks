from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lfsr_feedback(state:UInt64,taps:UnsafePointer[Int64,ImmutAnyOrigin],count:Int)->UInt64:
    var b:UInt64=0
    for i in range(count):b^=(state>>Int(taps[i]))&1
    return b
fn lfsr_step(mut state:UInt64,width:Int,mask:UInt64,taps:UnsafePointer[Int64,ImmutAnyOrigin],count:Int)->UInt64:
    let output=(state>> (width-1))&1
    state=((state<<1)|lfsr_feedback(state,taps,count))&mask
    return output
fn lfsr_put(out:UnsafePointer[UInt8,MutAnyOrigin],slot:Int,x:UInt64):
    for i in range(8):out[slot*8+i]=UInt8((x>>(8*i))&255)
@export("lfsr")
fn lfsr(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or v[0]<1 or v[0]>63 or v[1]<0 or v[1]>=v[0] or v[2]<0 or v[2]>63 or v[3]<0 or v[3]>256 or v[5]<0 or v[5]>4194303:return -1
    let width=Int(v[0]);let tc=Int(v[2]);let clocks=Int(v[3])
    if n!=c_size_t(6+tc):return -1
    for i in range(tc):
        if v[6+i]<0 or v[6+i]>=v[0]:return -1
    let mask=(UInt64(1)<<width)-1;var state:UInt64=0;let key=UInt64(v[4]);let frame=UInt64(v[5])
    for rb in range(64):
        let bit=63-rb;state=((state<<1)|(((key>>bit)&1)^lfsr_feedback(state,v+6,tc)))&mask
    for rb in range(22):
        let bit=21-rb;state=((state<<1)|(((frame>>bit)&1)^lfsr_feedback(state,v+6,tc)))&mask
    let needed=(clocks+2)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    lfsr_put(out,0,UInt64(clocks))
    for i in range(clocks):lfsr_put(out,i+1,lfsr_step(state,width,mask,v+6,tc))
    lfsr_put(out,clocks+1,state)
    return Int64(needed)
