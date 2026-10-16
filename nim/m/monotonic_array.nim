proc monotonic_array*(v: ptr int64,n:uint64):int64 {.cdecl,exportc.}=
 if n>256 or (v==nil and n>0):return -1
 var inc=true;var dec=true
 for i in 0..<int(n):if v[i]< -1000000000 or v[i]>1000000000:return -1
 for i in 1..<int(n):if v[i-1]>v[i]:inc=false;if v[i-1]<v[i]:dec=false
 if inc or dec:1 else:0
