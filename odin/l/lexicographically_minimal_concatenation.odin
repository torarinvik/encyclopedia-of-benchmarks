// Independent suffix-array/LCP draft; compilation and output are unverified.
package lexicographically_minimal_concatenation
import "core:c"

suffix_before :: proc(a,b,step: int, classes: []int) -> bool {
    if classes[a]!=classes[b] do return classes[a]<classes[b]
    aa,bb:=-1,-1
    if a+step<len(classes) { aa=classes[a+step] }
    if b+step<len(classes) { bb=classes[b+step] }
    return aa<bb
}
sort_suffixes :: proc(sa,scratch: []int, step: int, classes: []int) {
    width:=1
    for width<len(sa) {
        start:=0
        for start<len(sa) {
            mid:=min(start+width,len(sa)); end:=min(start+2*width,len(sa))
            a,b,out:=start,mid,start
            for a<mid && b<end {
                if suffix_before(sa[b],sa[a],step,classes) { scratch[out]=sa[b]; b+=1 } else { scratch[out]=sa[a]; a+=1 }
                out+=1
            }
            for a<mid { scratch[out]=sa[a]; a+=1; out+=1 }
            for b<end { scratch[out]=sa[b]; b+=1; out+=1 }
            start=end
        }
        for i:=0; i<len(sa); i+=1 { sa[i]=scratch[i] }
        width*=2
    }
}
Comparator :: struct { starts,sizes,text,rank,logs,table: []int, n: int }
common :: proc(ctx: ^Comparator, a,b,limit: int) -> int {
    if a==b do return limit
    lo:=min(ctx.rank[a],ctx.rank[b])+1; hi:=max(ctx.rank[a],ctx.rank[b])
    level:=ctx.logs[hi-lo+1]; span:=1<<uint(level)
    return min(limit,min(ctx.table[level*ctx.n+lo],ctx.table[level*ctx.n+hi-span+1]))
}
word_before :: proc(ctx: ^Comparator, a,b: int) -> bool {
    left:=[2]int{a,b}; right:=[2]int{b,a}
    li,ri,lp,rp:=0,0,0,0
    for li<2 && ri<2 {
        lw,rw:=left[li],right[ri]
        limit:=min(ctx.sizes[lw]-lp,ctx.sizes[rw]-rp)
        x,y:=ctx.starts[lw]+lp,ctx.starts[rw]+rp
        same:=common(ctx,x,y,limit)
        if same<limit do return ctx.text[x+same]<ctx.text[y+same]
        lp+=same; rp+=same
        if lp==ctx.sizes[lw] { li+=1; lp=0 }
        if rp==ctx.sizes[rw] { ri+=1; rp=0 }
    }
    return a<b
}
sort_words :: proc(order,scratch: []int, ctx: ^Comparator) {
    width:=1
    for width<len(order) {
        start:=0
        for start<len(order) {
            mid:=min(start+width,len(order)); end:=min(start+2*width,len(order))
            a,b,out:=start,mid,start
            for a<mid && b<end {
                if word_before(ctx,order[b],order[a]) { scratch[out]=order[b]; b+=1 } else { scratch[out]=order[a]; a+=1 }
                out+=1
            }
            for a<mid { scratch[out]=order[a]; a+=1; out+=1 }
            for b<end { scratch[out]=order[b]; b+=1; out+=1 }
            start=end
        }
        for i:=0; i<len(order); i+=1 { order[i]=scratch[i] }
        width*=2
    }
}

@(export)
lexicographically_minimal_concatenation :: proc "c" (input: [^]i64, length: c.size_t,
                                                      output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length==0 || input[0]<0 || input[0]>16384 do return -1
    count:=int(input[0]); offset,total:=1,0
    for i:=0; i<count; i+=1 {
        if offset>=int(length) || input[offset]<1 || input[offset]>65536 do return -1
        size:=int(input[offset]); offset+=1
        if size>65536-total || size>int(length)-offset do return -1
        for j:=0; j<size; j+=1 { if input[offset+j]<97 || input[offset+j]>122 do return -1 }
        offset+=size; total+=size
    }
    if offset!=int(length) do return -1
    if output==nil || capacity<c.size_t(total) do return -2
    if count==0 do return 0
    n:=total+count; levels:=1
    for (1<<uint(levels))<=n { levels+=1 }
    memory:=make([]int,(7+levels)*n+1+4*count); defer delete(memory)
    text:=memory[0:n]; sa:=memory[n:2*n]; scratch:=memory[2*n:3*n]
    classes:=memory[3*n:4*n]; next:=memory[4*n:5*n]; rank:=memory[5*n:6*n]
    logs:=memory[6*n:7*n+1]; table:=memory[7*n+1:(7+levels)*n+1]
    base:=(7+levels)*n+1
    starts:=memory[base:base+count]; sizes:=memory[base+count:base+2*count]
    order:=memory[base+2*count:base+3*count]; word_scratch:=memory[base+3*count:]
    offset=1; used:=0
    for i:=0; i<count; i+=1 {
        size:=int(input[offset]); offset+=1; starts[i]=used; sizes[i]=size
        for j:=0; j<size; j+=1 { text[used]=int(input[offset+j]); used+=1 }
        offset+=size; text[used]=0; used+=1
    }
    for i:=0; i<n; i+=1 { sa[i]=i; classes[i]=text[i] }
    step:=1
    for step<n {
        sort_suffixes(sa,scratch,step,classes)
        next[sa[0]]=0
        for i:=1; i<n; i+=1 {
            a,b:=sa[i-1],sa[i]; next[b]=next[a]
            if suffix_before(a,b,step,classes) { next[b]+=1 }
        }
        classes,next=next,classes
        if classes[sa[n-1]]==n-1 { break }
        step*=2
    }
    for i:=0; i<n; i+=1 { rank[sa[i]]=i }
    shared:=0
    for i:=0; i<n; i+=1 {
        r:=rank[i]
        if r==0 { shared=0; continue }
        j:=sa[r-1]
        for i+shared<n && j+shared<n && text[i+shared]==text[j+shared] { shared+=1 }
        table[r]=shared
        if shared>0 { shared-=1 }
    }
    for i:=2; i<=n; i+=1 { logs[i]=logs[i/2]+1 }
    for level:=1; level<levels; level+=1 {
        width:=1<<uint(level); half:=width/2
        for i:=0; i+width<=n; i+=1 { table[level*n+i]=min(table[(level-1)*n+i],table[(level-1)*n+i+half]) }
    }
    for i:=0; i<count; i+=1 { order[i]=i }
    ctx:=Comparator{starts,sizes,text,rank,logs,table,n}
    sort_words(order,word_scratch,&ctx)
    written:=0
    for i:=0; i<count; i+=1 {
        word:=order[i]
        for j:=0; j<sizes[word]; j+=1 { output[written]=u8(text[starts[word]+j]); written+=1 }
    }
    return i64(written)
}
