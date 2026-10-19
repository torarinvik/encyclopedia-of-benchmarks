from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn morse_idx(x:Int64)->Int:
    if x>=65 and x<=90:return Int(x-65)
    if x>=97 and x<=122:return Int(x-97)
    if x>=48 and x<=57:return 26+Int(x-48)
    return -1
fn morse_word(i:Int)->Int64:
    let words=InlineArray[Int64,36](514,1031,1029,771,257,1037,769,1039,515,1032,770,1035,512,513,768,1033,1026,773,775,256,774,1038,772,1030,1028,1027,1280,1296,1304,1308,1310,1311,1295,1287,1283,1281)
    return words[i]
@export("morse_code")
fn morse_code(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>682 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var required=0
    for i in range(Int(n)):
        let k=morse_idx(v[i]);if k<0:return -1
        required+=Int((morse_word(k)>>8)&7);if i>0:required+=1
    if cap<c_size_t(required) or (required>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var p=0
    for i in range(Int(n)):
        if i>0:o[p]=32;p+=1
        let w=morse_word(morse_idx(v[i]));let size=Int((w>>8)&7);let mask=Int(w&31)
        for j in range(size):o[p]=if ((mask>>(size-j-1))&1)!=0:46 else:45;p+=1
    return Int64(p)
