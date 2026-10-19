from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("unique_letters_count")
fn unique_letters_count(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let count=v[0]
    if count<0 or count>256 or n!=c_size_t(count+1):return -1
    var freq=InlineArray[Int64,26](fill=0);var order=InlineArray[Int,26](fill=0);var used=0
    for i in range(Int(count)):
        let ch=v[i+1]
        if ch<0 or ch>127:return -1
        var lower=ch
        if ch>=65 and ch<=90:lower=ch+32
        if lower>=97 and lower<=122:
            let idx=Int(lower-97)
            if freq[idx]==0:order[used]=idx;used+=1
            freq[idx]+=1
    if cap<c_size_t(8*min(Int(count),26)):return -2
    if used>0 and o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(used):
        let idx=order[i];let letter=UInt32(idx+97);let number=UInt32(freq[idx])
        for b in range(4):o[i*8+b]=UInt8((letter>>(8*b))&255);o[i*8+4+b]=UInt8((number>>(8*b))&255)
    return Int64(used)
