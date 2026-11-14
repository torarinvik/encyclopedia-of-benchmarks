# Independent suffix-array/LCP draft; compilation and output are unverified.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn suffix_before(a: Int, b: Int, step: Int, classes: List[Int]) -> Bool:
    if classes[a]!=classes[b]: return classes[a]<classes[b]
    var aa = -1
    var bb = -1
    if a+step<len(classes): aa=classes[a+step]
    if b+step<len(classes): bb=classes[b+step]
    return aa<bb

fn sort_suffixes(mut sa: List[Int], mut scratch: List[Int], step: Int, classes: List[Int]):
    let n=len(sa)
    var width=1
    while width<n:
        var start=0
        while start<n:
            let middle=min(start+width,n)
            let end=min(start+2*width,n)
            var a=start
            var b=middle
            var out=start
            while a<middle and b<end:
                if suffix_before(sa[b],sa[a],step,classes):
                    scratch[out]=sa[b]
                    b+=1
                else:
                    scratch[out]=sa[a]
                    a+=1
                out+=1
            while a<middle:
                scratch[out]=sa[a]
                a+=1
                out+=1
            while b<end:
                scratch[out]=sa[b]
                b+=1
                out+=1
            start=end
        for i in range(n): sa[i]=scratch[i]
        width*=2

fn common(a: Int, b: Int, limit: Int, n: Int, rank: List[Int], logs: List[Int], table: List[Int]) -> Int:
    if a==b: return limit
    let low=min(rank[a],rank[b])+1
    let high=max(rank[a],rank[b])
    let level=logs[high-low+1]
    let span=1<<level
    return min(limit,min(table[level*n+low],table[level*n+high-span+1]))

fn word_before(a: Int, b: Int, starts: List[Int], sizes: List[Int], text: List[Int],
               rank: List[Int], logs: List[Int], table: List[Int]) -> Bool:
    var li=0
    var ri=0
    var lp=0
    var rp=0
    while li<2 and ri<2:
        var lw=a
        var rw=b
        if li==1: lw=b
        if ri==1: rw=a
        let limit=min(sizes[lw]-lp,sizes[rw]-rp)
        let x=starts[lw]+lp
        let y=starts[rw]+rp
        let same=common(x,y,limit,len(text),rank,logs,table)
        if same<limit: return text[x+same]<text[y+same]
        lp+=same
        rp+=same
        if lp==sizes[lw]:
            li+=1
            lp=0
        if rp==sizes[rw]:
            ri+=1
            rp=0
    return a<b

fn sort_words(mut order: List[Int], mut scratch: List[Int], starts: List[Int], sizes: List[Int],
              text: List[Int], rank: List[Int], logs: List[Int], table: List[Int]):
    let count=len(order)
    var width=1
    while width<count:
        var start=0
        while start<count:
            let middle=min(start+width,count)
            let end=min(start+2*width,count)
            var a=start
            var b=middle
            var out=start
            while a<middle and b<end:
                if word_before(order[b],order[a],starts,sizes,text,rank,logs,table):
                    scratch[out]=order[b]
                    b+=1
                else:
                    scratch[out]=order[a]
                    a+=1
                out+=1
            while a<middle:
                scratch[out]=order[a]
                a+=1
                out+=1
            while b<end:
                scratch[out]=order[b]
                b+=1
                out+=1
            start=end
        for i in range(count): order[i]=scratch[i]
        width*=2

@export("lexicographically_minimal_concatenation")
fn lexicographically_minimal_concatenation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0: return -1
    if input[0]<0 or input[0]>16384: return -1
    let count=Int(input[0])
    var offset=1
    var total=0
    for _ in range(count):
        if offset>=Int(length) or input[offset]<1 or input[offset]>65536: return -1
        let size=Int(input[offset])
        offset+=1
        if size>65536-total or size>Int(length)-offset: return -1
        for j in range(size):
            if input[offset+j]<97 or input[offset+j]>122: return -1
        offset+=size
        total+=size
    if offset!=Int(length): return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(total): return -2
    if count==0: return 0
    let n=total+count
    var levels=1
    while (1<<levels)<=n: levels+=1
    var text=List[Int](length=n,fill=0)
    var sa=List[Int](length=n,fill=0)
    var scratch=List[Int](length=n,fill=0)
    var classes=List[Int](length=n,fill=0)
    var next=List[Int](length=n,fill=0)
    var rank=List[Int](length=n,fill=0)
    var logs=List[Int](length=n+1,fill=0)
    var table=List[Int](length=levels*n,fill=0)
    var starts=List[Int](length=count,fill=0)
    var sizes=List[Int](length=count,fill=0)
    var order=List[Int](length=count,fill=0)
    var word_scratch=List[Int](length=count,fill=0)
    offset=1
    var used=0
    for i in range(count):
        let size=Int(input[offset])
        offset+=1
        starts[i]=used
        sizes[i]=size
        for j in range(size):
            text[used]=Int(input[offset+j])
            used+=1
        offset+=size
        text[used]=0
        used+=1
    for i in range(n):
        sa[i]=i
        classes[i]=text[i]
    var step=1
    while step<n:
        sort_suffixes(sa,scratch,step,classes)
        next[sa[0]]=0
        for i in range(1,n):
            let a=sa[i-1]
            let b=sa[i]
            next[b]=next[a]
            if suffix_before(a,b,step,classes): next[b]+=1
        for i in range(n): classes[i]=next[i]
        if classes[sa[n-1]]==n-1: break
        step*=2
    for i in range(n): rank[sa[i]]=i
    var shared=0
    for i in range(n):
        let r=rank[i]
        if r==0:
            shared=0
            continue
        let j=sa[r-1]
        while i+shared<n and j+shared<n and text[i+shared]==text[j+shared]: shared+=1
        table[r]=shared
        if shared>0: shared-=1
    for i in range(2,n+1): logs[i]=logs[i//2]+1
    for level in range(1,levels):
        let width=1<<level
        let half=width//2
        for i in range(n-width+1):
            table[level*n+i]=min(table[(level-1)*n+i],table[(level-1)*n+i+half])
    for i in range(count): order[i]=i
    sort_words(order,word_scratch,starts,sizes,text,rank,logs,table)
    var written=0
    for i in range(count):
        let word=order[i]
        for j in range(sizes[word]):
            output[written]=UInt8(text[starts[word]+j])
            written+=1
    return Int64(written)
