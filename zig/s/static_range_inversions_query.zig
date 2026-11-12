const max_n: usize = 128;
const max_q: usize = 32;
const Query = struct { left: usize, right: usize, id: usize, block: usize };

fn lower_bound(a: *const [max_n]i64, n: usize, value: i64) usize {
    var lo: usize = 0;
    var hi = n;
    while (lo < hi) { const mid=lo+(hi-lo)/2;if(a[mid]<value){lo=mid+1;}else{hi=mid;} }
    return lo;
}
fn bit_sum(bit: *const [max_n + 1]i64, count: usize) i64 {
    var i=count;var sum:i64=0;while(i>0){sum+=bit[i];i-=i&(~i+1);}return sum;
}
fn bit_add(bit: *[max_n + 1]i64, rank: usize, delta: i64) void {
    var i=rank+1;while(i<=max_n){bit[i]+=delta;i+=i&(~i+1);}
}
fn before(a: Query, b: Query) bool {
    if(a.block!=b.block)return a.block<b.block;
    if(a.right!=b.right){if((a.block&1)==1)return a.right>b.right;return a.right<b.right;}
    return a.id<b.id;
}
fn put_i64_le(output:[*]u8,offset:usize,value:i64) void {
    const bits:u64=@bitCast(value);for(0..8)|byte|output[offset+byte]=@truncate(bits>>(8*byte));
}

export fn static_range_inversions_query(input_opt:?[*]const i64,length:usize,
        output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<2 or length>195)return -1;
    const input=input_opt.?;const nv=input[0];const qv=input[1];if(nv<1 or nv>128 or qv<1 or qv>32)return -1;
    const n:usize=@intCast(nv);const q:usize=@intCast(qv);if(length!=2+n+2*q)return -1;
    var values=[_]i64{0}**max_n;var sorted=[_]i64{0}**max_n;
    for(0..n)|i|{values[i]=input[2+i];if(values[i]<0 or values[i]>1_000_000_000)return -1;sorted[i]=values[i];}
    for(1..n)|i|{const x=sorted[i];var j=i;while(j>0 and sorted[j-1]>x):(j-=1){sorted[j]=sorted[j-1];}sorted[j]=x;}
    var distinct:usize=0;for(0..n)|i|{const x=sorted[i];if(distinct==0 or sorted[distinct-1]!=x){sorted[distinct]=x;distinct+=1;}}
    var ranks=[_]usize{0}**max_n;for(0..n)|i|ranks[i]=lower_bound(&sorted,distinct,values[i]);
    var block_size:usize=1;while((block_size+1)*(block_size+1)<=n){block_size+=1;}
    var queries=[_]Query{.{.left=0,.right=0,.id=0,.block=0}}**max_q;var off:usize=2+n;
    for(0..q)|k|{const l=input[off];const r=input[off+1];off+=2;if(l<0 or l>=r or r>nv)return -1;queries[k]=.{.left=@intCast(l),.right=@intCast(r),.id=k,.block=@as(usize,@intCast(l))/block_size};}
    for(1..q)|i|{const x=queries[i];var j=i;while(j>0 and before(x,queries[j-1])):(j-=1){queries[j]=queries[j-1];}queries[j]=x;}
    var bit=[_]i64{0}**(max_n+1);var answers=[_]i64{0}**max_q;var left:usize=0;var right:usize=0;var window:usize=0;var inversions:i64=0;
    for(0..q)|qi|{const query=queries[qi];
        while(left>query.left){left-=1;const rank=ranks[left];inversions+=bit_sum(&bit,rank);bit_add(&bit,rank,1);window+=1;}
        while(right<query.right){const rank=ranks[right];inversions+=@as(i64,@intCast(window))-bit_sum(&bit,rank+1);bit_add(&bit,rank,1);window+=1;right+=1;}
        while(left<query.left){const rank=ranks[left];inversions-=bit_sum(&bit,rank);bit_add(&bit,rank,-1);window-=1;left+=1;}
        while(right>query.right){right-=1;const rank=ranks[right];inversions-=@as(i64,@intCast(window))-bit_sum(&bit,rank+1);bit_add(&bit,rank,-1);window-=1;}
        answers[query.id]=inversions;
    }
    const bytes=8*q;if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;for(0..q)|k|put_i64_le(output,8*k,answers[k]);return @intCast(bytes);
}
