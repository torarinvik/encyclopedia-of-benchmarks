from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

fn bucket_sort_key(value:Int64)->UInt64:
    let sign=UInt64(1)<<63
    if value<0:return sign-1-UInt64(-(value+1))
    return sign+UInt64(value)

@export("bucket_sort")
fn bucket_sort(values:UnsafePointer[Int64,MutAnyOrigin],scratch:UnsafePointer[Int64,MutAnyOrigin],length:c_size_t) abi("C"):
    if length<2:return
    for b in range(256):scratch[b]=0
    for i in range(Int(length)):
        let b=Int(bucket_sort_key(values[i])>>56);scratch[b]+=1
    var next=0
    for b in range(256):
        let count=Int(scratch[b]);scratch[b]=Int64(next);next+=count
    for i in range(Int(length)):
        let b=Int(bucket_sort_key(values[i])>>56);let dest=Int(scratch[b]);scratch[b]+=1;scratch[256+dest]=values[i]
    var low=0
    for b in range(256):
        let high=Int(scratch[b])
        for i in range(low+1,high):
            let key=scratch[256+i];var pos=i
            while pos>low and scratch[256+pos-1]>key:scratch[256+pos]=scratch[256+pos-1];pos-=1
            scratch[256+pos]=key
        low=high
    for i in range(Int(length)):values[i]=scratch[256+i]
