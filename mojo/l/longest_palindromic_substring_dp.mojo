from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn alnum_dp(x:Int64)->Bool:return (x>=48 and x<=57) or (x>=65 and x<=90) or (x>=97 and x<=122)
@export("longest_palindromic_substring_dp")
fn longest_palindromic_substring_dp(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>1000:return -1
    for i in range(Int(n)):
        if not alnum_dp(v[i]):return -1
    var pal=InlineArray[UInt8,1000000](fill=UInt8(0));var bs=0;var be=0
    for gap in range(Int(n)):
        for start in range(Int(n)-gap):
            let end=start+gap;var yes=False
            if gap==0:yes=True
            elif gap==1:yes=v[start]==v[end]
            else:yes=v[start]==v[end] and pal[(start+1)*Int(n)+end-1]!=0
            pal[start*Int(n)+end]=UInt8(yes)
            if yes:bs=start;be=end
    let length=be-bs+1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(length):return -2
    for i in range(length):out[i]=UInt8(v[bs+i])
    return Int64(length)
