module range_add_range_min

struct Tree {
mut:
    minimum [256]i64
    lazy [256]i64
}

fn build(mut tree Tree, input &i64, node int, left int, right int) {
    unsafe {
        if right-left==1 { tree.minimum[node]=input[2+left]; return }
        middle:=(left+right)/2
        build(mut tree,input,2*node,left,middle)
        build(mut tree,input,2*node+1,middle,right)
        tree.minimum[node]=min(tree.minimum[2*node],tree.minimum[2*node+1])
    }
}
fn push(mut tree Tree, node int) {
    for child:=2*node;child<=2*node+1;child++ {
        tree.minimum[child]+=tree.lazy[node]
        tree.lazy[child]+=tree.lazy[node]
    }
    tree.lazy[node]=0
}
fn add(mut tree Tree, node int, left int, right int, first int, last int, delta i64) {
    if last<=left || right<=first { return }
    if first<=left && right<=last { tree.minimum[node]+=delta; tree.lazy[node]+=delta; return }
    push(mut tree,node)
    middle:=(left+right)/2
    add(mut tree,2*node,left,middle,first,last,delta)
    add(mut tree,2*node+1,middle,right,first,last,delta)
    tree.minimum[node]=min(tree.minimum[2*node],tree.minimum[2*node+1])
}
fn query(mut tree Tree, node int, left int, right int, first int, last int) i64 {
    if last<=left || right<=first { return i64(9223372036854775807) }
    if first<=left && right<=last { return tree.minimum[node] }
    push(mut tree,node)
    middle:=(left+right)/2
    a:=query(mut tree,2*node,left,middle,first,last)
    b:=query(mut tree,2*node+1,middle,right,first,last)
    return min(a,b)
}
@[export: 'range_add_range_min']
pub fn range_add_range_min(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length<2 || length>322 || input[0]<1 || input[0]>64 || input[1]<1 || input[1]>64 { return -1 }
        n:=int(input[0]); q:=int(input[1]); mut queries:=0
        if length!=usize(2+n+4*q) { return -1 }
        for i in 0 .. n { if input[2+i]<-1000000 || input[2+i]>1000000 { return -1 } }
        for i in 0 .. q {
            base:=2+n+4*i
            op:=input[base]; left:=input[base+1]; right:=input[base+2]; delta:=input[base+3]
            if left<0 || left>=right || right>i64(n) { return -1 }
            if op==0 { if delta < -100000 || delta > 100000 { return -1 } }
            else if op==1 { if delta!=0 { return -1 }; queries++ }
            else { return -1 }
        }
        if queries==0 { return -1 }
        if isnil(output) || capacity<usize(8*queries) { return -2 }
        mut tree:=Tree{}
        build(mut tree,input,1,0,n)
        mut written:=0
        for i in 0 .. q {
            base:=2+n+4*i; left:=int(input[base+1]); right:=int(input[base+2])
            if input[base]==0 { add(mut tree,1,0,n,left,right,input[base+3]) }
            else {
                value:=query(mut tree,1,0,n,left,right)
                bits:=u64(value)
                for byte in 0 .. 8 { output[8*written+byte]=u8((bits >> (8*byte)) & 255) }
                written++
            }
        }
        return i64(8*written)
    }
}
