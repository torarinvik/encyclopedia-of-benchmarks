from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("problem13_chunks")
fn problem13_chunks(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>5001:return -1
    if v[0]<1 or v[0]>5000 or c_size_t(v[0])!=n-1:return -1
    let length=Int(v[0])
    for i in range(length):if v[i+1]<48 or v[i+1]>57:return -1
    let width=length if length<50 else 50
    var reversed=InlineArray[UInt8,52](fill=0);var used=0;var carry=Int64(0)
    for rem in range(width):
        let position=width-1-rem;var column=carry;var start=0
        while start<length:
            let chunk_len=(length-start) if length-start<50 else 50
            if position<chunk_len:column+=v[1+start+position]-48
            start+=50
        reversed[used]=UInt8(column%10);used+=1;carry=column//10
    while carry>0:reversed[used]=UInt8(carry%10);used+=1;carry//=10
    let output_length=used if used<10 else 10
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(output_length):return -2
    for i in range(output_length):out[i]=48+reversed[used-1-i]
    return Int64(output_length)
