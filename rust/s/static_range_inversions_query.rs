const MAX_N: usize = 128;
const MAX_Q: usize = 32;
#[derive(Clone, Copy)]
struct Query { left: usize, right: usize, id: usize, block: usize }

fn lower_bound(a: &[i64; MAX_N], n: usize, x: i64) -> usize {
    let (mut lo, mut hi) = (0, n);
    while lo < hi { let mid=lo+(hi-lo)/2; if a[mid]<x {lo=mid+1;} else {hi=mid;} }
    lo
}
fn bit_sum(bit: &[i64; MAX_N+1], mut count: usize) -> i64 {
    let mut sum=0;while count>0{sum+=bit[count];count-=count & count.wrapping_neg();}sum
}
fn bit_add(bit: &mut [i64; MAX_N+1], rank: usize, delta: i64) {
    let mut i=rank+1;while i<=MAX_N{bit[i]+=delta;i+=i & i.wrapping_neg();}
}
fn put_i64_le(out:*mut u8,at:usize,value:i64){unsafe{let bits=value as u64;for b in 0..8{*out.add(at+b)=(bits>>(8*b)) as u8;}}}

#[no_mangle]
pub unsafe extern "C" fn static_range_inversions_query(input:*const i64,length:usize,
        output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<2||length>195{return -1;}
    let n64=*input;let q64=*input.add(1);if n64<1||n64>128||q64<1||q64>32{return -1;}
    let n=n64 as usize;let q=q64 as usize;if length!=2+n+2*q{return -1;}
    let mut values=[0i64;MAX_N];let mut sorted=[0i64;MAX_N];
    for i in 0..n{values[i]=*input.add(2+i);if values[i]<0||values[i]>1_000_000_000{return -1;}sorted[i]=values[i];}
    sorted[..n].sort();let mut distinct=0;for read in 0..n{let x=sorted[read];if distinct==0||sorted[distinct-1]!=x{sorted[distinct]=x;distinct+=1;}}
    let mut ranks=[0usize;MAX_N];for i in 0..n{ranks[i]=lower_bound(&sorted,distinct,values[i]);}
    let mut block=1usize;while (block+1)*(block+1)<=n{block+=1;}
    let mut queries=[Query{left:0,right:0,id:0,block:0};MAX_Q];let mut off=2+n;
    for k in 0..q{let l=*input.add(off);let r=*input.add(off+1);off+=2;if l<0||l>=r||r>n64{return -1;}queries[k]=Query{left:l as usize,right:r as usize,id:k,block:l as usize/block};}
    queries[..q].sort_by(|a,b|a.block.cmp(&b.block).then_with(||if a.block&1==0{a.right.cmp(&b.right)}else{b.right.cmp(&a.right)}).then(a.id.cmp(&b.id)));
    let mut bit=[0i64;MAX_N+1];let mut answers=[0i64;MAX_Q];let(mut left,mut right,mut window)=(0usize,0usize,0usize);let mut inversions=0i64;
    for z in &queries[..q]{
        while left>z.left{left-=1;let x=ranks[left];inversions+=bit_sum(&bit,x);bit_add(&mut bit,x,1);window+=1;}
        while right<z.right{let x=ranks[right];inversions+=window as i64-bit_sum(&bit,x+1);bit_add(&mut bit,x,1);window+=1;right+=1;}
        while left<z.left{let x=ranks[left];inversions-=bit_sum(&bit,x);bit_add(&mut bit,x,-1);window-=1;left+=1;}
        while right>z.right{right-=1;let x=ranks[right];inversions-=window as i64-bit_sum(&bit,x+1);bit_add(&mut bit,x,-1);window-=1;}
        answers[z.id]=inversions;
    }
    let bytes=8*q;if output.is_null()||capacity<bytes{return -2;}for k in 0..q{put_i64_le(output,8*k,answers[k]);}bytes as i64
}
