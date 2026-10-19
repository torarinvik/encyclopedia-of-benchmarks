from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("phonetic_alphabet_converter")
fn phonetic_alphabet_converter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<0 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<576:return -2
    let words=InlineArray[String,36]("Alpha","Bravo","Charlie","Delta","Echo","Foxtrot","Golf","Hotel","India","Juliett","Kilo","Lima","Mike","November","Oscar","Papa","Quebec","Romeo","Sierra","Tango","Uniform","Victor","Whiskey","X-ray","Yankee","Zulu","Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine")
    var at=0;var emitted=0
    for i in range(Int(v[0])):
        let z=v[i+1]
        if z<0 or z>127 or not ((z>=33 and z<=126) or (z>=9 and z<=13) or z==32):return -1
        if z==32 or (z>=9 and z<=13):continue
        let c=if z>=97 and z<=122:Int(z-32) else:Int(z)
        if emitted>0:o[at]=32;at+=1
        emitted+=1
        if c>=65 and c<=90:
            let s=words[c-65]
            for b in s.as_bytes():o[at]=b;at+=1
        elif c>=48 and c<=57:
            let s=words[26+c-48]
            for b in s.as_bytes():o[at]=b;at+=1
        else:o[at]=UInt8(c);at+=1
    return Int64(at)
