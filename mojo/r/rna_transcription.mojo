from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("rna_transcription")
fn rna_transcription(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1001 or v[0]!=0:return -1
    for i in range(1,Int(n)):if v[i]!=65 and v[i]!=67 and v[i]!=71 and v[i]!=84:return -1
    let count=Int(n)-1;if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(count):
        let x=v[i+1];if x==65:o[i]=85 elif x==67:o[i]=71 elif x==71:o[i]=67 else:o[i]=65
    return Int64(count)
