package persistent_range_affine_range_sum
import "core:c"
MOD :: i64(998244353)
Q :: 16
CAP :: 4096
Node :: struct { sum, mul, add: i64, left, right: int }
norm :: proc "contextless" (x0:i64)->i64 { x:=x0%MOD; if x<0{return x+MOD}; return x }
clone :: proc "contextless" (a:[^]Node,used:^int,s:int)->int {if s<0||used^>=CAP{return -1};d:=used^;used^+=1;a[d]=a[s];return d}
make :: proc "contextless" (a:[^]Node,used:^int,sum:i64,l,r:int)->int {if used^>=CAP{return -1};d:=used^;used^+=1;a[d]=Node{sum,1,0,l,r};return d}
apply :: proc "contextless" (a:[^]Node,x:int,m0,b0:i64,n:int){m:=norm(m0);b:=norm(b0);a[x].sum=norm(m*a[x].sum+b*i64(n));a[x].mul=norm(m*a[x].mul);a[x].add=norm(m*a[x].add+b)}
push :: proc "contextless" (a:[^]Node,used:^int,x,l,r:int)->bool {m:=a[x].mul;b:=a[x].add;if m==1&&b==0{return true};if l<r{mid:=l+(r-l)/2;lc:=clone(a,used,a[x].left);rc:=clone(a,used,a[x].right);if lc<0||rc<0{return false};a[x].left=lc;a[x].right=rc;apply(a,lc,m,b,mid-l+1);apply(a,rc,m,b,r-mid)};a[x].mul=1;a[x].add=0;return true}
build :: proc "contextless" (a:[^]Node,used:^int,v:[^]i64,l,r:int)->int {if l==r{return make(a,used,v[2+l],-1,-1)};mid:=l+(r-l)/2;x:=build(a,used,v,l,mid);y:=build(a,used,v,mid+1,r);if x<0||y<0{return -1};return make(a,used,norm(a[x].sum+a[y].sum),x,y)}
update :: proc "contextless" (a:[^]Node,used:^int,root,l,r,ql,qr:int,m,b:i64)->int {if ql<=l&&r<=qr{x:=clone(a,used,root);if x<0{return -1};apply(a,x,m,b,r-l+1);return x};x:=clone(a,used,root);if x<0||!push(a,used,x,l,r){return -1};mid:=l+(r-l)/2;if ql<=mid{y:=update(a,used,a[x].left,l,mid,ql,qr,m,b);if y<0{return -1};a[x].left=y};if qr>mid{y:=update(a,used,a[x].right,mid+1,r,ql,qr,m,b);if y<0{return -1};a[x].right=y};a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum);return x}
logical_child :: proc "contextless" (a:[^]Node,used:^int,s:int,right:bool,l,r:int)->int {c:=clone(a,used,if right{a[s].right}else{a[s].left});if c<0{return -1};m:=a[s].mul;b:=a[s].add;if m!=1||b!=0{mid:=l+(r-l)/2;apply(a,c,m,b,if right{r-mid}else{mid-l+1})};return c}
copy_range :: proc "contextless" (a:[^]Node,used:^int,dst,src,l,r,ql,qr:int)->int {if ql<=l&&r<=qr{return src};x:=clone(a,used,dst);if x<0||!push(a,used,x,l,r){return -1};mid:=l+(r-l)/2;if ql<=mid{s:=logical_child(a,used,src,false,l,r);if s<0{return -1};y:=copy_range(a,used,a[x].left,s,l,mid,ql,qr);if y<0{return -1};a[x].left=y};if qr>mid{s:=logical_child(a,used,src,true,l,r);if s<0{return -1};y:=copy_range(a,used,a[x].right,s,mid+1,r,ql,qr);if y<0{return -1};a[x].right=y};a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum);return x}
query :: proc "contextless" (a:[^]Node,x,l,r,ql,qr:int,cm,ca:i64)->i64 {if ql<=l&&r<=qr{return norm(cm*a[x].sum+ca*i64(r-l+1))};mid:=l+(r-l)/2;nm:=norm(cm*a[x].mul);na:=norm(cm*a[x].add+ca);mut z:=i64(0);if ql<=mid{z=query(a,a[x].left,l,mid,ql,qr,nm,na)};if qr>mid{z=norm(z+query(a,a[x].right,mid+1,r,ql,qr,nm,na))};return z}
valid_ref :: proc "contextless" (k:i64,i:int,kinds:[Q]i64)->bool{return k==-1||(k>=0&&int(k)<i&&(kinds[int(k)]==0||kinds[int(k)]==1))}
put :: proc "contextless" (out:[^]u8,at:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{out[at+j]=u8(b>>(8*j))}}
@(export)
persistent_range_affine_range_sum :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<2||length>115{return -1};n0:=input[0];q0:=input[1];if n0<1||n0>16||q0<1||q0>16{return -1};n:=int(n0);q:=int(q0);mut off:=2+n;if int(length)<off{return -1};for j:=0;j<n;j+=1{if input[2+j]<0||input[2+j]>=MOD{return -1}}
 mut kind,refs,src,ls,rs,mul,add:[Q]i64;for i:=0;i<Q;i+=1{mul[i]=1}
 for i:=0;i<q;i+=1{if off>=int(length){return -1};op:=input[off];w:=if op==0{6}else if op==1{5}else if op==2{4}else{0};if w==0||int(length)-off<w{return -1};k:=input[off+1];if !valid_ref(k,i,kind){return -1};kind[i]=op;refs[i]=k;if op==0||op==2{ls[i]=input[off+2];rs[i]=input[off+3];if ls[i]<0||rs[i]<=ls[i]||rs[i]>n0{return -1}};if op==0{mul[i]=input[off+4];add[i]=input[off+5];if mul[i]<1||mul[i]>=MOD||add[i]<0||add[i]>=MOD{return -1}};if op==1{src[i]=input[off+2];ls[i]=input[off+3];rs[i]=input[off+4];if !valid_ref(src[i],i,kind)||ls[i]<0||rs[i]<=ls[i]||rs[i]>n0{return -1}};off+=w};if off!=int(length){return -1}
 var nodes:[CAP]Node;mut used:=0;initial:=build(&nodes[0],&used,&input[0],0,n-1);if initial<0{return -1};mut roots:[Q]int;mut ans:[Q]i64;mut na:=0
 for i:=0;i<q;i+=1{base:=if refs[i]<0{initial}else{roots[int(refs[i])]};if kind[i]==0{roots[i]=update(&nodes[0],&used,base,0,n-1,int(ls[i]),int(rs[i])-1,mul[i],add[i]);if roots[i]<0{return -1}}else if kind[i]==1{s:=if src[i]<0{initial}else{roots[int(src[i])]};roots[i]=copy_range(&nodes[0],&used,base,s,0,n-1,int(ls[i]),int(rs[i])-1);if roots[i]<0{return -1}}else{ans[na]=query(&nodes[0],base,0,n-1,int(ls[i]),int(rs[i])-1,1,0);na+=1}}
 bytes:=8*na;if output==nil||capacity<c.size_t(bytes){return -2};for i:=0;i<na;i+=1{put(&output[0],8*i,ans[i])};return i64(bytes)
}
