proc lee_breadth_first_search*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"lee_breadth_first_search".}=
 if v.isNil or n<6 or n>70:return -2
 let r=v[0];let c=v[1];let sr=v[2];let sc=v[3];let dr=v[4];let dc=v[5]
 if r<1 or r>8 or c<1 or c>8 or n!=csize_t(6+r*c) or sr<0 or sr>=r or dr<0 or dr>=r or sc<0 or sc>=c or dc<0 or dc>=c:return -2
 var a:array[64,int64];var d:array[64,int64];var q:array[64,int]
 for i in 0..<r*c:
  a[i]=v[6+i];if a[i]!=0 and a[i]!=1:return -2
  d[i]= -1
 let s=int(sr*c+sc);let t=int(dr*c+dc);if a[s]==0 or a[t]==0:return -1
 var h=0;var z=1;q[0]=s;d[s]=0
 while h<z:
  let u=q[h];inc h;if u==t:return d[u]
  let y=u div int(c);let x=u mod int(c)
  let ys=[y-1,y,y,y+1];let xs=[x,x-1,x+1,x]
  for k in 0..3:
   if ys[k]>=0 and ys[k]<int(r) and xs[k]>=0 and xs[k]<int(c):
    let w=ys[k]*int(c)+xs[k]
    if a[w]==1 and d[w]<0:d[w]=d[u]+1;q[z]=w;inc z
 -1
