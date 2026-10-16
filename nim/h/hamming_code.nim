proc hamming_code*(a:ptr UncheckedArray[int64],n:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"hamming_code".}=
 if a==nil or n<3:return -1
 let r=a[0];let m=a[1]
 if r<1 or r>5 or m<1 or m>32 or n!=csize_t(2+m) or r+m<=((1'i64 shl int(r))-(m-1)):return -1
 for i in 0..<int(m):if a[2+i]!=48 and a[2+i]!=49:return -1
 let total=int(r+m)
 if total < (1 shl int(r-1)):return -1
 if out==nil or cap<csize_t(total+1):return -2
 var code:array[40,uint8];var data=0
 for p in 1..total:
  if (p and (p-1))!=0 or p>(1 shl (int(r)-1)):code[p-1]=uint8(a[2+data]);inc data
  else:code[p-1]=uint8(ord('0'))
 for bit in 0..<int(r):
  let parity=1 shl bit;var value=0
  for p in 1..total:if (p and parity)!=0 and code[p-1]==uint8(ord('1')):value=value xor 1
  code[parity-1]=uint8(ord('0')+value)
 for i in 0..<total:out[i]=code[i]
 out[total]=0
 int64(total)
