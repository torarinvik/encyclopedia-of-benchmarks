from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn pat_less(keys:InlineArray[Int64,1024],a:Int,b:Int)->Bool:return keys[a]<keys[b] or (keys[a]==keys[b] and a<b)
fn pat_sift(keys:InlineArray[Int64,1024],mut heap:InlineArray[Int64,1024],length:Int,mut root:Int):
    while root<length/2:
        var child=2*root+1
        if child+1<length and pat_less(keys,Int(heap[child+1]),Int(heap[child])):child+=1
        if not pat_less(keys,Int(heap[child]),Int(heap[root])):break
        let x=heap[root];heap[root]=heap[child];heap[child]=x;root=child
@export("patience_sort")
fn patience_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n<2 or n>1024:return
    let len=Int(n);var keys=InlineArray[Int64,1024](fill=0);var tops=InlineArray[Int64,1024](fill=0);var next=InlineArray[Int64,1024](fill=0);var heap=InlineArray[Int64,1024](fill=0);var piles=0
    for i in range(len):
        keys[i]=v[i];next[i]=Int64(len);var lo=0;var hi=piles
        while lo<hi:let mid=lo+(hi-lo)/2;if keys[Int(tops[mid])]>=keys[i]:hi=mid else:lo=mid+1
        if lo==piles:tops[piles]=Int64(i);piles+=1
        else:next[i]=tops[lo];tops[lo]=Int64(i)
    for i in range(piles):heap[i]=tops[i]
    var hlen=piles;var start=hlen/2
    while start>0:start-=1;var root=start;pat_sift(keys,mut heap,hlen,mut root)
    var out=0
    while hlen>0:
        let node=Int(heap[0]);v[out]=keys[node];out+=1;let succ=Int(next[node])
        if succ<len:heap[0]=Int64(succ)
        else:hlen-=1;if hlen>0:heap[0]=heap[hlen]
        if hlen>0:var root=0;pat_sift(keys,mut heap,hlen,mut root)
