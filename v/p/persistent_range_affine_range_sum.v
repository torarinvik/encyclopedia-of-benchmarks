module persistent_range_affine_range_sum

const mod = i64(998244353)
const qcap = 16
const cap = 4096
struct Node { mut: sum i64; mul i64; add i64; left int; right int }
fn norm(x i64) i64 { return (x % mod + mod) % mod }
fn clone(mut a [cap]Node, mut used int, s int) int { if s<0 || used>=cap{return -1};d:=used;used++;a[d]=a[s];return d }
fn make(mut a [cap]Node, mut used int, sum i64, l int, r int) int { if used>=cap{return -1};d:=used;used++;a[d]=Node{sum:sum,mul:1,left:l,right:r};return d }
fn apply(mut a [cap]Node,x int,m i64,b i64,len int){mm:=norm(m);bb:=norm(b);a[x].sum=norm(mm*a[x].sum+bb*i64(len));a[x].mul=norm(mm*a[x].mul);a[x].add=norm(mm*a[x].add+bb)}
fn push(mut a [cap]Node,mut used int,x int,l int,r int) bool {m:=a[x].mul;b:=a[x].add;if m==1&&b==0{return true};if l<r{mid:=l+(r-l)/2;lc:=clone(mut a,mut used,a[x].left);rc:=clone(mut a,mut used,a[x].right);if lc<0||rc<0{return false};a[x].left=lc;a[x].right=rc;apply(mut a,lc,m,b,mid-l+1);apply(mut a,rc,m,b,r-mid)};a[x].mul=1;a[x].add=0;return true}
fn build(mut a [cap]Node,mut used int,v &i64,offset int,l int,r int) int {if l==r{return make(mut a,mut used,v[offset+l],-1,-1)};mid:=l+(r-l)/2;x:=build(mut a,mut used,v,offset,l,mid);y:=build(mut a,mut used,v,offset,mid+1,r);if x<0||y<0{return -1};return make(mut a,mut used,norm(a[x].sum+a[y].sum),x,y)}
fn update(mut a [cap]Node,mut used int,root int,l int,r int,ql int,qr int,m i64,b i64) int {if ql<=l&&r<=qr{x:=clone(mut a,mut used,root);if x<0{return -1};apply(mut a,x,m,b,r-l+1);return x};x:=clone(mut a,mut used,root);if x<0||!push(mut a,mut used,x,l,r){return -1};mid:=l+(r-l)/2;if ql<=mid{y:=update(mut a,mut used,a[x].left,l,mid,ql,qr,m,b);if y<0{return -1};a[x].left=y};if qr>mid{y:=update(mut a,mut used,a[x].right,mid+1,r,ql,qr,m,b);if y<0{return -1};a[x].right=y};a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum);return x}
fn logical_child(mut a [cap]Node,mut used int,s int,right bool,l int,r int) int {c:=clone(mut a,mut used,if right{a[s].right}else{a[s].left});if c<0{return -1};m:=a[s].mul;b:=a[s].add;if m!=1||b!=0{mid:=l+(r-l)/2;apply(mut a,c,m,b,if right{r-mid}else{mid-l+1})};return c}
fn copy_range(mut a [cap]Node,mut used int,dst int,src int,l int,r int,ql int,qr int) int {if ql<=l&&r<=qr{return src};x:=clone(mut a,mut used,dst);if x<0||!push(mut a,mut used,x,l,r){return -1};mid:=l+(r-l)/2;if ql<=mid{s:=logical_child(mut a,mut used,src,false,l,r);if s<0{return -1};y:=copy_range(mut a,mut used,a[x].left,s,l,mid,ql,qr);if y<0{return -1};a[x].left=y};if qr>mid{s:=logical_child(mut a,mut used,src,true,l,r);if s<0{return -1};y:=copy_range(mut a,mut used,a[x].right,s,mid+1,r,ql,qr);if y<0{return -1};a[x].right=y};a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum);return x}
fn query(a [cap]Node,x int,l int,r int,ql int,qr int,cm i64,ca i64) i64 {if ql<=l&&r<=qr{return norm(cm*a[x].sum+ca*i64(r-l+1))};mid:=l+(r-l)/2;nm:=norm(cm*a[x].mul);na:=norm(cm*a[x].add+ca);mut z:=i64(0);if ql<=mid{z=query(a,a[x].left,l,mid,ql,qr,nm,na)};if qr>mid{z=norm(z+query(a,a[x].right,mid+1,r,ql,qr,nm,na))};return z}
fn valid_ref(k i64,i int,kinds [qcap]i64) bool {return k==-1||(k>=0&&int(k)<i&&(kinds[int(k)]==0||kinds[int(k)]==1))}
fn put(mut out &u8,at int,value i64){bits:=u64(value);for j in 0..8{out[at+j]=u8(bits>>(8*j))}}
@[export: 'persistent_range_affine_range_sum']
pub fn persistent_range_affine_range_sum(input &i64,length usize,mut output &u8,capacity usize) i64 {
 if unsafe{input==nil}||length<2||length>115{return -1};n0:=input[0];q0:=input[1];if n0<1||n0>16||q0<1||q0>16{return -1};n:=int(n0);q:=int(q0);mut off:=2+n;if int(length)<off{return -1};for j in 0..n{if input[2+j]<0||input[2+j]>=mod{return -1}}
 mut kind:=[qcap]i64{};mut refs:=[qcap]i64{};mut src:=[qcap]i64{};mut ls:=[qcap]i64{};mut rs:=[qcap]i64{};mut muls:=[qcap]i64{};mut adds:=[qcap]i64{};for i in 0..q{muls[i]=1}
 for i in 0..q{if off>=int(length){return -1};op:=input[off];w:=if op==0{6}else if op==1{5}else if op==2{4}else{0};if w==0||int(length)-off<w{return -1};k:=input[off+1];if !valid_ref(k,i,kind){return -1};kind[i]=op;refs[i]=k;if op==0||op==2{ls[i]=input[off+2];rs[i]=input[off+3];if ls[i]<0||rs[i]<=ls[i]||rs[i]>n0{return -1}};if op==0{muls[i]=input[off+4];adds[i]=input[off+5];if muls[i]<1||muls[i]>=mod||adds[i]<0||adds[i]>=mod{return -1}};if op==1{src[i]=input[off+2];ls[i]=input[off+3];rs[i]=input[off+4];if !valid_ref(src[i],i,kind)||ls[i]<0||rs[i]<=ls[i]||rs[i]>n0{return -1}};off+=w};if off!=int(length){return -1}
 mut nodes:=[cap]Node{};mut used:=0;initial:=build(mut nodes,mut used,input,2,0,n-1);if initial<0{return -1};mut roots:=[qcap]int{};mut answers:=[qcap]i64{};mut na:=0
 for i in 0..q{base:=if refs[i]<0{initial}else{roots[int(refs[i])]};if kind[i]==0{roots[i]=update(mut nodes,mut used,base,0,n-1,int(ls[i]),int(rs[i])-1,muls[i],adds[i]);if roots[i]<0{return -1}}else if kind[i]==1{s:=if src[i]<0{initial}else{roots[int(src[i])]};roots[i]=copy_range(mut nodes,mut used,base,s,0,n-1,int(ls[i]),int(rs[i])-1);if roots[i]<0{return -1}}else{answers[na]=query(nodes,base,0,n-1,int(ls[i]),int(rs[i])-1,1,0);na++}}
 bytes:=8*na;if unsafe{output==nil}||capacity<usize(bytes){return -2};for i in 0..na{put(mut output,8*i,answers[i])};return i64(bytes)
}
