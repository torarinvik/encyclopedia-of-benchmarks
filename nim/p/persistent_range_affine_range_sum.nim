const Mod = 998244353'i64
const MaxQ = 16
const Cap = 4096
type Node = object
  sum, mul, add: int64
  left, right: int32
proc norm(x: int64): int64 = ((x mod Mod) + Mod) mod Mod
proc clone(a: var array[Cap,Node], used: var int, s: int32): int32 =
  if s < 0 or used >= Cap: return -1
  result = int32(used); a[used] = a[int(s)]; inc used
proc make(a: var array[Cap,Node], used: var int, sum: int64, l, r: int32): int32 =
  if used >= Cap: return -1
  result = int32(used); a[used] = Node(sum: sum, mul: 1, add: 0, left: l, right: r); inc used
proc apply(a: var array[Cap,Node], x: int32, m, b: int64, len: int) =
  let mm = norm(m); let bb = norm(b); let i = int(x)
  a[i].sum = norm(mm*a[i].sum + bb*int64(len)); a[i].mul = norm(mm*a[i].mul); a[i].add = norm(mm*a[i].add+bb)
proc push(a: var array[Cap,Node], used: var int, x: int32, l,r: int): bool =
  let i=int(x); let m=a[i].mul; let b=a[i].add
  if m==1 and b==0: return true
  if l<r:
    let mid=l+(r-l) div 2
    let lc=clone(a,used,a[i].left); let rc=clone(a,used,a[i].right)
    if lc<0 or rc<0: return false
    a[i].left=lc; a[i].right=rc; apply(a,lc,m,b,mid-l+1); apply(a,rc,m,b,r-mid)
  a[i].mul=1; a[i].add=0; true
proc build(a: var array[Cap,Node], used: var int, v: ptr UncheckedArray[int64], l,r: int): int32 =
  if l==r: return make(a,used,v[2+l],-1,-1)
  let mid=l+(r-l) div 2; let x=build(a,used,v,l,mid); let y=build(a,used,v,mid+1,r)
  if x<0 or y<0: return -1
  make(a,used,norm(a[int(x)].sum+a[int(y)].sum),x,y)
proc update(a: var array[Cap,Node],used: var int,root:int32,l,r,ql,qr:int,m,b:int64):int32 =
  if ql<=l and r<=qr:
    let x=clone(a,used,root); if x<0:return -1; apply(a,x,m,b,r-l+1); return x
  let x=clone(a,used,root); if x<0 or not push(a,used,x,l,r):return -1
  let mid=l+(r-l) div 2
  if ql<=mid:
    let y=update(a,used,a[int(x)].left,l,mid,ql,qr,m,b); if y<0:return -1; a[int(x)].left=y
  if qr>mid:
    let y=update(a,used,a[int(x)].right,mid+1,r,ql,qr,m,b); if y<0:return -1; a[int(x)].right=y
  a[int(x)].sum=norm(a[int(a[int(x)].left)].sum+a[int(a[int(x)].right)].sum); x
proc logicalChild(a:var array[Cap,Node],used:var int,s:int32,right:bool,l,r:int):int32 =
  let si=int(s); let c=clone(a,used,if right:a[si].right else:a[si].left); if c<0:return -1
  let m=a[si].mul;let b=a[si].add
  if m!=1 or b!=0:
    let mid=l+(r-l) div 2;apply(a,c,m,b,if right:r-mid else:mid-l+1)
  c
proc copyRange(a:var array[Cap,Node],used:var int,dst,src:int32,l,r,ql,qr:int):int32 =
  if ql<=l and r<=qr:return src
  let x=clone(a,used,dst);if x<0 or not push(a,used,x,l,r):return -1
  let mid=l+(r-l) div 2
  if ql<=mid:
    let s=logicalChild(a,used,src,false,l,r);if s<0:return -1
    let y=copyRange(a,used,a[int(x)].left,s,l,mid,ql,qr);if y<0:return -1;a[int(x)].left=y
  if qr>mid:
    let s=logicalChild(a,used,src,true,l,r);if s<0:return -1
    let y=copyRange(a,used,a[int(x)].right,s,mid+1,r,ql,qr);if y<0:return -1;a[int(x)].right=y
  a[int(x)].sum=norm(a[int(a[int(x)].left)].sum+a[int(a[int(x)].right)].sum);x
proc query(a:var array[Cap,Node],x:int32,l,r,ql,qr:int,cm,ca:int64):int64 =
  if ql<=l and r<=qr:return norm(cm*a[int(x)].sum+ca*int64(r-l+1))
  let mid=l+(r-l) div 2;let nm=norm(cm*a[int(x)].mul);let na=norm(cm*a[int(x)].add+ca);var z=0'i64
  if ql<=mid:z=query(a,a[int(x)].left,l,mid,ql,qr,nm,na)
  if qr>mid:z=norm(z+query(a,a[int(x)].right,mid+1,r,ql,qr,nm,na));z
proc validRef(k:int64,i:int,kinds:array[MaxQ,int64]):bool = k == -1 or (k>=0 and int(k)<i and (kinds[int(k)]==0 or kinds[int(k)]==1))
proc put(output:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[at+j]=uint8((bits shr (8*j)) and 255)
proc persistent_range_affine_range_sum*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"persistent_range_affine_range_sum".} =
  if input.isNil or length<2 or length>115:return -1
  let n0=input[0];let q0=input[1];if n0<1 or n0>16 or q0<1 or q0>16:return -1
  let n=int(n0);let q=int(q0);var off=2+n;if int(length)<off:return -1
  var vals:array[16,int64]
  for j in 0..<n:vals[j]=input[2+j];if vals[j]<0 or vals[j]>=Mod:return -1
  var kind,refs,src,ls,rs,muls,adds:array[MaxQ,int64]
  for i in 0..<MaxQ: muls[i]=1
  for i in 0..<q:
    if off>=int(length):return -1
    let op=input[off];let w=if op==0:6 elif op==1:5 elif op==2:4 else:0
    if w==0 or int(length)-off<w:return -1
    let k=input[off+1];if not validRef(k,i,kind):return -1
    kind[i]=op;refs[i]=k
    if op==0 or op==2:
      ls[i]=input[off+2];rs[i]=input[off+3];if ls[i]<0 or rs[i]<=ls[i] or rs[i]>n0:return -1
    if op==0:
      muls[i]=input[off+4];adds[i]=input[off+5];if muls[i]<1 or muls[i]>=Mod or adds[i]<0 or adds[i]>=Mod:return -1
    if op==1:
      src[i]=input[off+2];ls[i]=input[off+3];rs[i]=input[off+4]
      if not validRef(src[i],i,kind) or ls[i]<0 or rs[i]<=ls[i] or rs[i]>n0:return -1
    off+=w
  if off!=int(length):return -1
  var nodes:array[Cap,Node];var used=0;let initial=build(nodes,used,input,0,n-1);if initial<0:return -1
  var roots:array[MaxQ,int32];var ans:array[MaxQ,int64];var na=0
  for i in 0..<q:
    let base=if refs[i]<0:initial else:roots[int(refs[i])]
    if kind[i]==0:
      roots[i]=update(nodes,used,base,0,n-1,int(ls[i]),int(rs[i])-1,muls[i],adds[i]);if roots[i]<0:return -1
    elif kind[i]==1:
      let s=if src[i]<0:initial else:roots[int(src[i])]
      roots[i]=copyRange(nodes,used,base,s,0,n-1,int(ls[i]),int(rs[i])-1);if roots[i]<0:return -1
    else:ans[na]=query(nodes,base,0,n-1,int(ls[i]),int(rs[i])-1,1,0);inc na
  let bytes=8*na;if output.isNil or int(capacity)<bytes:return -2
  for i in 0..<na:put(output,8*i,ans[i]);int64(bytes)
