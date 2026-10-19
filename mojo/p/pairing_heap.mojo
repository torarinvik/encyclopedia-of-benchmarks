from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn ph_meld(mut first:Int,mut second:Int,mut keys:InlineArray[Int32,128],mut child:InlineArray[Int64,128],mut sibling:InlineArray[Int64,128])->Int:
    if first<0:return second
    if second<0:return first
    if keys[second]<keys[first]:let t=first;first=second;second=t
    sibling[second]=child[first];child[first]=Int64(second);sibling[first]=-1
    return first
fn ph_hash(mut h:UInt64,x:Int32)->UInt64:
    let u=UInt32(x)
    for b in range(4):h=(h^UInt64((u>>(8*b))&255))*1099511628211
    return h
@export("pairing_heap")
fn pairing_heap(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130 or v[0]<2 or v[0]>128 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var keys=InlineArray[Int32,128](fill=0);var child=InlineArray[Int64,128](fill=-1);var sibling=InlineArray[Int64,128](fill=-1)
    for i in range(count):
        if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1
        for j in range(i):if v[i+1]==v[j+1]:return -1
        keys[i]=Int32(v[i+1])
    var root=-1
    for i in range(count):root=ph_meld(root,i,mut keys,mut child,mut sibling)
    var h:UInt64=14695981039346656037
    for _ in range(count-1):
        let removed=root;h=ph_hash(h,keys[removed]);var forest=InlineArray[Int64,128](fill=-1);var fc=0;var c=Int(child[removed]);child[removed]=-1
        while c>=0:let nx=Int(sibling[c]);sibling[c]=-1;forest[fc]=Int64(c);fc+=1;c=nx
        var paired=InlineArray[Int64,128](fill=-1);var pc=0;var i=0
        while i<fc:let right=if i+1<fc:Int(forest[i+1]) else:-1;paired[pc]=Int64(ph_meld(Int(forest[i]),right,mut keys,mut child,mut sibling));pc+=1;i+=2
        var rebuilt=-1
        while pc>0:pc-=1;rebuilt=ph_meld(rebuilt,Int(paired[pc]),mut keys,mut child,mut sibling)
        root=rebuilt
    return Int64(h&0x7fffffffffffffff)
