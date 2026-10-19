from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn topk_sift(inout heap:InlineArray[Int,64],counts:InlineArray[Int,64],size:Int,root0:Int):
    var root=root0
    while True:
        var best=root;let left=root*2+1;let right=left+1
        if left<size and counts[heap[left]]>counts[heap[best]]:best=left
        if right<size and counts[heap[right]]>counts[heap[best]]:best=right
        if best==root:break
        let t=heap[root];heap[root]=heap[best];heap[best]=t;root=best
fn topk_run(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t,lex:Bool)->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1090 or a[0]<0 or a[0]>64 or a[1]<0 or a[1]>64:return -1
    let k=Int(a[0]);let nw=Int(a[1]);var lens=InlineArray[Int,64]();var counts=InlineArray[Int,64]();var words=InlineArray[Int,1024]();var distinct=0;var pos=2
    for _ in range(nw):
        if pos>=Int(n) or a[pos]<1 or a[pos]>16 or a[pos]>Int(n)-pos-1:return -1
        let len=Int(a[pos]);pos+=1
        for j in range(len):
            if a[pos+j]<97 or a[pos+j]>122:return -1
        var id=0
        while id<distinct:
            if lens[id]==len:
                var j=0
                while j<len and words[id*16+j]==a[pos+j]:j+=1
                if j==len:break
            id+=1
        if id==distinct:
            lens[id]=len
            for j in range(len):words[id*16+j]=Int(a[pos+j])
            distinct+=1
        counts[id]+=1;pos+=len
    if pos!=Int(n):return -1
    if lex:
        for id in range(distinct):
            var rank=0
            for other in range(distinct):
                let common=min(lens[id],lens[other]);var j=0
                while j<common and words[other*16+j]==words[id*16+j]:j+=1
                if (j<common and words[other*16+j]<words[id*16+j]) or (j==common and lens[other]<lens[id]):rank+=1
            counts[id]=counts[id]*65+distinct-rank
    var heap=InlineArray[Int,64]()
    for i in range(distinct):heap[i]=i
    for i in range(distinct/2):topk_sift(heap,counts,distinct,distinct/2-1-i)
    let limit=min(k,distinct);var out=InlineArray[UInt8,1089]();var size=distinct;var at=0
    for _ in range(limit):
        let id=heap[0]
        for j in range(lens[id]):out[at]=UInt8(words[id*16+j]);at+=1
        out[at]=10;at+=1
        size-=1;heap[0]=heap[size]
        if size>0:topk_sift(heap,counts,size,0)
    out[at]=0;at+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(at):return -2
    for i in range(at):o[i]=out[i]
    return Int64(at)
@export("top_k_frequent_words")
fn top_k_frequent_words(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    return topk_run(a,n,o,cap,False)
@export("top_kfrequent_words")
fn top_kfrequent_words(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    return topk_run(a,n,o,cap,True)
