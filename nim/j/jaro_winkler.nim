proc jaro_winkler*(v:ptr UncheckedArray[int64],n:csize_t):cdouble {.cdecl,exportc:"jaro_winkler".}=
 const bad = -1.0e300
 if v.isNil or n<2 or n>66:return bad
 let n1=v[0];if n1<0 or n1>32 or 1+n1>=n:return bad
 let p2=1+int(n1);let n2=v[p2];if n2<0 or n2>32 or n!=csize_t(p2+1+int(n2)):return bad
 for i in 0..<int(n1):if v[1+i]<0 or v[1+i]>127:return bad
 for i in 0..<int(n2):if v[p2+1+i]<0 or v[p2+1+i]>127:return bad
 let radius=min(n1,n2) div 2
 var u1,u2:array[32,bool];var a,b:array[32,int64];var ca=0;var cb=0
 for i in 0..<int(n1):
  let lo=max(0,i-int(radius));let hi=min(i+int(radius)+1,int(n2))
  for j in lo..<hi:
   if not u2[j] and v[1+i]==v[p2+1+j]:u2[j]=true;a[ca]=v[1+i];inc ca;break
 for i in 0..<int(n2):
  let lo=max(0,i-int(radius));let hi=min(i+int(radius)+1,int(n1))
  for j in lo..<hi:
   if not u1[j] and v[p2+1+i]==v[1+j]:u1[j]=true;b[cb]=v[p2+1+i];inc cb;break
 var trans=0
 for i in 0..<min(ca,cb):
  if a[i]!=b[i]:inc trans
 trans=trans div 2
 var jr=0.0;if ca>0:jr=(ca.float/n1.float+ca.float/n2.float+(ca.float-trans.float)/ca.float)/3.0
 var prefix=0;while prefix<4 and prefix<int(n1) and prefix<int(n2) and v[1+prefix]==v[p2+1+prefix]:inc prefix
 jr+0.1*prefix.float*(1.0-jr)
