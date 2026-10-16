type Node = object
 key:int64
 left,right,npl:int
proc mergeNodes(a:var array[14,Node],x0,y0:int):int=
 if x0<0:return y0
 if y0<0:return x0
 var x=x0;var y=y0
 if a[x].key>a[y].key:swap(x,y)
 a[x].right=mergeNodes(a,a[x].right,y)
 if a[x].left<0:a[x].left=a[x].right;a[x].right= -1
 else:
  if a[a[x].left].npl<a[a[x].right].npl:swap(a[x].left,a[x].right)
  a[x].npl=a[a[x].right].npl+1
 x
proc leftist_heap(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"leftist_heap".}=
 if n<1 or n>43:return -1e300
 let m=v[0]
 if m<0 or m>14 or n!=csize_t(1+3*m):return -1e300
 var a:array[14,Node];var roots=[-1,-1];var used=0;var ex=0;var result:int64=0
 for i in 0..<int(m):
  let k=v[1+3*i];let h=v[2+3*i];let z=v[3+3*i]
  if k<0 or k>3:return -1e300
  if k==0:
   if h<0 or h>1 or z<0 or z>9:return -1e300
   a[used]=Node(key:z,left: -1,right: -1,npl:0);roots[int(h)]=mergeNodes(a,used,roots[int(h)]);inc used
  elif k==1:
   if h<0 or h>1 or z!=0:return -1e300
   inc ex;if ex>10:return -1e300
   let r=roots[int(h)];var got:int64= -1
   if r>=0:got=a[r].key;let l=a[r].left;let rr=a[r].right;roots[int(h)]=mergeNodes(a,l,rr)
   result=result*13+got+2
  elif k==2:
   if h!=0 or z!=0:return -1e300
   roots[0]=mergeNodes(a,roots[0],roots[1]);roots[1]= -1
  else:
   if h<0 or h>1 or z!=0:return -1e300
   roots[int(h)]= -1
 float64(result)
