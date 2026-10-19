from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("palindromic_substrings")
fn palindromic_substrings(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n==0 or n>1000 or v==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    for i in range(Int(n)):if v[i]<97 or v[i]>122:return -1
    var count:Int64=0;let len=Int(n)
    for c in range(len):
        count+=1;var l=c;var r=c
        while l>0 and r+1<len and v[l-1]==v[r+1]:count+=1;l-=1;r+=1
        l=c;r=c+1
        while r<len and v[l]==v[r]:count+=1;if l==0 or r+1==len:break;l-=1;r+=1
    return count
