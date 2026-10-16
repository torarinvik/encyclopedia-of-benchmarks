proc largest_square_area_in_matrix*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"largest_square_area_in_matrix".}=
 if v.isNil or n<2 or n>66:return -2
 let r=v[0];let c=v[1]
 if r<1 or r>8 or c<1 or c>8 or n!=csize_t(2+r*c):return -2
 var a:array[64,int64];var d:array[9,array[9,int64]];var best=0'i64
 for i in 0..<r*c:a[i]=v[2+i];if a[i]!=0 and a[i]!=1:return -2
 for ii in countdown(int(r)-1,0):
  for jj in countdown(int(c)-1,0):
   let i=ii;let j=jj
   if a[i*int(c)+j]==1:d[i][j]=1+min(d[i+1][j],min(d[i][j+1],d[i+1][j+1]));best=max(best,d[i][j])
 best
