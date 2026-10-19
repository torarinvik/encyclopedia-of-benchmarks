from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn msds_bucket(data:InlineArray[Int32,8192], lens:InlineArray[Int32,256], idx:Int, digit:Int)->Int:
    if digit>=lens[idx]:return 0
    return Int(data[idx*32+digit])+1
fn msds_rec(mut data:InlineArray[Int32,8192],mut aux:InlineArray[Int32,8192],lens:InlineArray[Int32,256],lo:Int,hi:Int,digit:Int):
    if hi-lo<2 or digit>=32:return
    var counts=InlineArray[Int64,257](fill=0)
    for i in range(lo,hi):counts[msds_bucket(data,lens,i,digit)]+=1
    var starts=InlineArray[Int64,257](fill=0);var next=InlineArray[Int64,257](fill=0);var pos=lo
    for b in range(257):starts[b]=pos;next[b]=pos;pos+=Int(counts[b])
    for i in range(lo,hi):let b=msds_bucket(data,lens,i,digit);let dest=Int(next[b]);next[b]+=1;for k in range(32):aux[dest*32+k]=data[i*32+k]
    for i in range(lo,hi):for k in range(32):data[i*32+k]=aux[i*32+k]
    for b in range(1,257):let a=Int(starts[b]);let z=a+Int(counts[b]);if z-a>1:msds_rec(data,aux,lens,a,z,digit+1)
fn msds_hash(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("msd_radix_string_sorter")
fn msd_radix_string_sorter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>8449:return -1
    let count=Int(v[0]);if count<0 or count>256:return -1
    var data=InlineArray[Int32,8192](fill=0);var aux=InlineArray[Int32,8192](fill=0);var lens=InlineArray[Int32,256](fill=0);var p=1
    for i in range(count):
        if p>=Int(n):return -1
        let size=Int(v[p]);p+=1;if size<0 or size>32 or p+size>Int(n):return -1;lens[i]=Int32(size)
        for j in range(size):let b=v[p];p+=1;if b<0 or b>255:return -1;data[i*32+j]=Int32(b)
    if p!=Int(n):return -1
    if count>1:msds_rec(data,aux,lens,0,count,0)
    var h:UInt64=14695981039346656037;h=msds_hash(h,UInt8(count&255));h=msds_hash(h,UInt8((count>>8)&255))
    for i in range(count):h=msds_hash(h,UInt8(lens[i]));for j in range(Int(lens[i])):h=msds_hash(h,UInt8(data[i*32+j]))
    return Int64(h&0x7fffffffffffffff)
