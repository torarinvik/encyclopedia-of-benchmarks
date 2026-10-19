from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn pan_flip(v:UnsafePointer[Int64,MutAnyOrigin],last:Int):
    var a=0;var b=last
    while a<b:let x=v[a];v[a]=v[b];v[b]=x;a+=1;b-=1
@export("pancake_sort")
fn pancake_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    var prefix=Int(n)
    while prefix>1:
        var max=0
        for i in range(1,prefix):if v[i]>v[max]:max=i
        if max!=prefix-1:pan_flip(v,max);pan_flip(v,prefix-1)
        prefix-=1
