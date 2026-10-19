from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("vigenere_cipher")
fn vigenere_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    var sep=0
    while sep<Int(n) and v[sep]!=0:sep+=1
    if sep==Int(n) or sep+1==Int(n):return -1
    let kl=Int(n)-sep-1
    for i in range(sep):if v[i]<1 or v[i]>127:return -1
    for i in range(kl):
        let x=v[sep+1+i]
        if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
    if cap<c_size_t(sep) or (sep>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var result=InlineArray[UInt8,65](fill=0);var ki=0
    for i in range(sep):
        let c=v[i];var m=c
        if c>=65 and c<=90:
            var k=v[sep+1+ki];if k>=97:k-=32
            m=65+(c-65+k-65)%26;ki=(ki+1)%kl
        elif c>=97 and c<=122:
            var k=v[sep+1+ki];if k<=90:k+=32
            m=97+(c-97+k-97)%26;ki=(ki+1)%kl
        result[i]=UInt8(m)
    for i in range(sep):o[i]=result[i]
    return Int64(sep)
