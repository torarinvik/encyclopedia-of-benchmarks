from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn intro_swap(v:UnsafePointer[Int64,MutAnyOrigin],a:Int,b:Int):
    let t=v[a];v[a]=v[b];v[b]=t
fn intro_insert(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int):
    for i in range(lo+1,hi):
        let key=v[i];var p=i
        while p>lo and v[p-1]>key:v[p]=v[p-1];p-=1
        v[p]=key
fn intro_sift(v:UnsafePointer[Int64,MutAnyOrigin],start:Int,count:Int,root0:Int):
    var root=root0
    while root<count//2:
        var child=root*2+1
        if child+1<count and v[start+child]<v[start+child+1]:child+=1
        if v[start+root]>=v[start+child]:return
        intro_swap(v,start+root,start+child);root=child
fn intro_heap(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,count:Int):
    var p=count//2
    while p>0:p-=1;intro_sift(v,lo,count,p)
    var end=count
    while end>1:end-=1;intro_swap(v,lo,lo+end);intro_sift(v,lo,end,0)
fn intro_partition(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int)->Int:
    let last=hi-1;intro_swap(v,lo+(hi-lo)//2,last);let pivot=v[last];var boundary=lo
    for probe in range(lo,last):
        if v[probe]<=pivot:intro_swap(v,boundary,probe);boundary+=1
    intro_swap(v,boundary,last)
    return boundary
fn intro_range(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int,depth:Int):
    let count=hi-lo
    if count<=16:intro_insert(v,lo,hi);return
    if depth==0:intro_heap(v,lo,count);return
    let pivot=intro_partition(v,lo,hi)
    intro_range(v,lo,pivot,depth-1);intro_range(v,pivot+1,hi,depth-1)

@export("intro_sort")
fn intro_sort(values:UnsafePointer[Int64,MutAnyOrigin],length:c_size_t) abi("C"):
    if length<2:return
    var n=Int(length);var log=0
    while n>1:n>>=1;log+=1
    intro_range(values,0,Int(length),2*log)
