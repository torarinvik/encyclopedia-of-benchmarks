module tournament_sort
const max_values=512
fn choose(values []i64,tree []int,left int,right int)int{l:=tree[left];r:=tree[right];if l<0{return r};if r<0{return l};return if values[l]<=values[r]{l}else{r}}
fn put_i64(out &u8,offset int,value i64){bits:=u64(value);for b in 0..8{unsafe{out[offset+b]=u8(bits>>(b*8))}}}
@[export:'tournament_sort']
pub fn tournament_sort(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<1{return -1};n64:=unsafe{input};if n64<0||n64>max_values{return -1};n:=int(n64);if length!=usize(1+n){return -1};mut values:=[]i64{len:n};for i in 0..n{v:=unsafe{input[i+1]};if v < -2147483648 || v > 2147483647{return -1};values[i]=v}
 mut leaves:=1;for leaves<n{leaves*=2};mut tree:=[]int{len:2*max_values+1,init:-1};for i in 0..n{tree[leaves+i]=i};if leaves>1{for node in 1..leaves{idx:=leaves-node;tree[idx]=choose(values,tree,idx*2,idx*2+1)}}
 bytes:=(1+n)*8;if isnil(output)||capacity<usize(bytes){return -2};put_i64(output,0,i64(n));for out in 0..n{w:=tree[1];put_i64(output,(1+out)*8,values[w]);mut node:=leaves+w;tree[node]=-1;for node>1{node/=2;tree[node]=choose(values,tree,node*2,node*2+1)}};return i64(bytes)
}
