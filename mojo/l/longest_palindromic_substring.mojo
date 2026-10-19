from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn alnum(x:Int64)->Bool:return (x>=48 and x<=57) or (x>=65 and x<=90) or (x>=97 and x<=122)
@export("longest_palindromic_substring")
fn longest_palindromic_substring(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>1000:return -1
    for i in range(Int(n)):
        if not alnum(v[i]):return -1
    var bs=0;var bl=1
    for center in range(Int(n)):
        var l=center;var r=center
        while l>0 and r+1<Int(n) and v[l-1]==v[r+1]:l-=1;r+=1
        let clen=r-l+1
        if clen>bl:bs=l;bl=clen
        l=center;r=center+1
        while r<Int(n) and v[l]==v[r]:
            let cand=r-l+1
            if cand>bl:bs=l;bl=cand
            if l==0 or r+1==Int(n):break
            l-=1;r+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bl):return -2
    for i in range(bl):out[i]=UInt8(v[bs+i])
    return Int64(bl)
