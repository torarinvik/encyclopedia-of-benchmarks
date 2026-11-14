const Tree = struct {
    minimum: [256]i64 = @splat(0),
    lazy: [256]i64 = @splat(0),

    fn build(t: *Tree, input: [*c]const i64, node: usize, left: usize, right: usize) void {
        if (right-left==1) { t.minimum[node]=input[2+left]; return; }
        const middle=(left+right)/2;
        t.build(input,2*node,left,middle);
        t.build(input,2*node+1,middle,right);
        t.minimum[node]=@min(t.minimum[2*node],t.minimum[2*node+1]);
    }
    fn push(t: *Tree, node: usize) void {
        for (2*node..2*node+2) |child| {
            t.minimum[child]+=t.lazy[node]; t.lazy[child]+=t.lazy[node];
        }
        t.lazy[node]=0;
    }
    fn add(t: *Tree, node: usize, left: usize, right: usize, first: usize, last: usize, delta: i64) void {
        if (last<=left or right<=first) return;
        if (first<=left and right<=last) { t.minimum[node]+=delta; t.lazy[node]+=delta; return; }
        t.push(node);
        const middle=(left+right)/2;
        t.add(2*node,left,middle,first,last,delta);
        t.add(2*node+1,middle,right,first,last,delta);
        t.minimum[node]=@min(t.minimum[2*node],t.minimum[2*node+1]);
    }
    fn query(t: *Tree, node: usize, left: usize, right: usize, first: usize, last: usize) i64 {
        if (last<=left or right<=first) return 9223372036854775807;
        if (first<=left and right<=last) return t.minimum[node];
        t.push(node);
        const middle=(left+right)/2;
        const a=t.query(2*node,left,middle,first,last);
        const b=t.query(2*node+1,middle,right,first,last);
        return @min(a,b);
    }
};

pub export fn range_add_range_min(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input==null or length<2 or length>322 or input[0]<1 or input[0]>64 or input[1]<1 or input[1]>64) return -1;
    const n:usize=@intCast(input[0]); const q:usize=@intCast(input[1]);
    if (length!=2+n+4*q) return -1;
    for (0..n) |i| if (input[2+i]<-1000000 or input[2+i]>1000000) { return -1; };
    var queries:usize=0;
    for (0..q) |i| {
        const base=2+n+4*i;
        const op=input[base]; const left=input[base+1]; const right=input[base+2]; const delta=input[base+3];
        if (left<0 or left>=right or right>@as(i64,@intCast(n))) return -1;
        if (op==0) { if (delta < -100000 or delta > 100000) return -1; }
        else if (op==1) { if (delta!=0) return -1; queries+=1; }
        else return -1;
    }
    if (queries==0) return -1;
    if (output==null or capacity<8*queries) return -2;
    var tree=Tree{}; tree.build(input,1,0,n);
    var written:usize=0;
    for (0..q) |i| {
        const base=2+n+4*i;
        const left:usize=@intCast(input[base+1]); const right:usize=@intCast(input[base+2]);
        if (input[base]==0) tree.add(1,0,n,left,right,input[base+3]) else {
            const bits:u64=@bitCast(tree.query(1,0,n,left,right));
            for (0..8) |byte| output[8*written+byte]=@truncate(bits >> @as(u6,@intCast(8*byte)));
            written+=1;
        }
    }
    return @intCast(8*written);
}
