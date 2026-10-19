from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn low(x:Int)->Int: return if x>=65 and x<=90:x+32 else:x
fn vowel(x:Int)->Bool:return x==97 or x==101 or x==105 or x==111 or x==117
@export("remove_vowels")
fn remove_vowels(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4097 or v[0]<0 or v[0]>4096 or Int(n)!=Int(v[0])+1:return -1
    var count=0
    for i in range(Int(v[0])):
        let x=v[i+1];if x<0 or x>127:return -1
        if not vowel(low(Int(x))):count+=1
    if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0
    for i in range(Int(v[0])):
        let x=low(Int(v[i+1]));if not vowel(x):o[w]=UInt8(x);w+=1
    return Int64(w)
