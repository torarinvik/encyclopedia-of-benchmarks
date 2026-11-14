// Independent suffix-array/LCP draft; compilation and output are unverified.
module lexicographically_minimal_concatenation

fn suffix_before(a int, b int, step int, classes []int) bool {
    if classes[a]!=classes[b] { return classes[a]<classes[b] }
    aa:=if a+step<classes.len { classes[a+step] } else { -1 }
    bb:=if b+step<classes.len { classes[b+step] } else { -1 }
    return aa<bb
}
fn sort_suffixes(mut sa []int, mut scratch []int, step int, classes []int) {
    mut width:=1
    for width<sa.len {
        mut start:=0
        for start<sa.len {
            mid:=if start+width<sa.len { start+width } else { sa.len }
            end:=if start+2*width<sa.len { start+2*width } else { sa.len }
            mut a:=start; mut b:=mid; mut out:=start
            for a<mid && b<end {
                if suffix_before(sa[b],sa[a],step,classes) { scratch[out]=sa[b]; b++ }
                else { scratch[out]=sa[a]; a++ }
                out++
            }
            for a<mid { scratch[out]=sa[a]; a++; out++ }
            for b<end { scratch[out]=sa[b]; b++; out++ }
            start=end
        }
        for i in 0 .. sa.len { sa[i]=scratch[i] }
        width*=2
    }
}
struct CompareContext {
    starts []int
    sizes []int
    text []int
    rank []int
    logs []int
    table []int
    n int
}
fn common(ctx CompareContext, a int, b int, limit int) int {
    if a==b { return limit }
    lo:=if ctx.rank[a]<ctx.rank[b] { ctx.rank[a]+1 } else { ctx.rank[b]+1 }
    hi:=if ctx.rank[a]>ctx.rank[b] { ctx.rank[a] } else { ctx.rank[b] }
    level:=ctx.logs[hi-lo+1]
    span:=1<<level
    x:=ctx.table[level*ctx.n+lo]; y:=ctx.table[level*ctx.n+hi-span+1]
    best:=if x<y { x } else { y }
    return if best<limit { best } else { limit }
}
fn word_before(ctx CompareContext, a int, b int) bool {
    left:=[a,b]; right:=[b,a]
    mut li:=0; mut ri:=0; mut lp:=0; mut rp:=0
    for li<2 && ri<2 {
        lw:=left[li]; rw:=right[ri]
        ln:=ctx.sizes[lw]-lp; rn:=ctx.sizes[rw]-rp
        limit:=if ln<rn { ln } else { rn }
        x:=ctx.starts[lw]+lp; y:=ctx.starts[rw]+rp
        same:=common(ctx,x,y,limit)
        if same<limit { return ctx.text[x+same]<ctx.text[y+same] }
        lp+=same; rp+=same
        if lp==ctx.sizes[lw] { li++; lp=0 }
        if rp==ctx.sizes[rw] { ri++; rp=0 }
    }
    return a<b
}
fn sort_words(mut order []int, mut scratch []int, ctx CompareContext) {
    mut width:=1
    for width<order.len {
        mut start:=0
        for start<order.len {
            mid:=if start+width<order.len { start+width } else { order.len }
            end:=if start+2*width<order.len { start+2*width } else { order.len }
            mut a:=start; mut b:=mid; mut out:=start
            for a<mid && b<end {
                if word_before(ctx,order[b],order[a]) { scratch[out]=order[b]; b++ }
                else { scratch[out]=order[a]; a++ }
                out++
            }
            for a<mid { scratch[out]=order[a]; a++; out++ }
            for b<end { scratch[out]=order[b]; b++; out++ }
            start=end
        }
        for i in 0 .. order.len { order[i]=scratch[i] }
        width*=2
    }
}

@[export: 'lexicographically_minimal_concatenation']
pub fn lexicographically_minimal_concatenation(input &i64, length usize, output &u8, capacity usize) i64 {
    if length==0 { return -1 }
    unsafe {
        if input==nil || input[0]<0 || input[0]>16384 { return -1 }
        count:=int(input[0])
        mut offset:=1; mut total:=0
        for _ in 0 .. count {
            if offset>=int(length) || input[offset]<1 || input[offset]>65536 { return -1 }
            size:=int(input[offset]); offset++
            if size>65536-total || size>int(length)-offset { return -1 }
            for j in 0 .. size { if input[offset+j]<97 || input[offset+j]>122 { return -1 } }
            offset+=size; total+=size
        }
        if offset!=int(length) { return -1 }
        if output==nil || capacity<usize(total) { return -2 }
        if count==0 { return 0 }
        n:=total+count
        mut levels:=1
        for (1<<levels)<=n { levels++ }
        mut text:=[]int{len:n}; mut sa:=[]int{len:n}; mut scratch:=[]int{len:n}
        mut classes:=[]int{len:n}; mut next:=[]int{len:n}; mut rank:=[]int{len:n}
        mut logs:=[]int{len:n+1}; mut table:=[]int{len:levels*n}
        mut starts:=[]int{len:count}; mut sizes:=[]int{len:count}
        mut order:=[]int{len:count}; mut word_scratch:=[]int{len:count}
        offset=1; mut used:=0
        for i in 0 .. count {
            size:=int(input[offset]); offset++
            starts[i]=used; sizes[i]=size
            for j in 0 .. size { text[used]=int(input[offset+j]); used++ }
            offset+=size; text[used]=0; used++
        }
        for i in 0 .. n { sa[i]=i; classes[i]=text[i] }
        mut step:=1
        for step<n {
            sort_suffixes(mut sa,mut scratch,step,classes)
            next[sa[0]]=0
            for i in 1 .. n {
                a:=sa[i-1]; b:=sa[i]
                next[b]=next[a]
                if suffix_before(a,b,step,classes) { next[b]++ }
            }
            for i in 0 .. n { classes[i]=next[i] }
            if classes[sa[n-1]]==n-1 { break }
            step*=2
        }
        for i in 0 .. n { rank[sa[i]]=i }
        mut shared:=0
        for i in 0 .. n {
            r:=rank[i]
            if r==0 { shared=0; continue }
            j:=sa[r-1]
            for i+shared<n && j+shared<n && text[i+shared]==text[j+shared] { shared++ }
            table[r]=shared
            if shared>0 { shared-- }
        }
        for i in 2 .. n+1 { logs[i]=logs[i/2]+1 }
        for level in 1 .. levels {
            width:=1<<level; half:=width/2
            for i in 0 .. n-width+1 {
                a:=table[(level-1)*n+i]; b:=table[(level-1)*n+i+half]
                table[level*n+i]=if a<b { a } else { b }
            }
        }
        for i in 0 .. count { order[i]=i }
        ctx:=CompareContext{starts:starts,sizes:sizes,text:text,rank:rank,logs:logs,table:table,n:n}
        sort_words(mut order,mut word_scratch,ctx)
        mut written:=0
        for word in order {
            for j in 0 .. sizes[word] { output[written]=u8(text[starts[word]+j]); written++ }
        }
        return i64(written)
    }
}
