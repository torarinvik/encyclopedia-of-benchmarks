proc ipv6_converter*(a:ptr UncheckedArray[int64],n:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"ipv6_converter".}=
 if a==nil or n<2:return -1
 let op=a[0];let len=a[1]
 if not ((op==0 and len==4) or (op==1 and len==16)) or n!=csize_t(2+len):return -1
 for i in 0..<int(len):if a[i+2]<0 or a[i+2]>255:return -1
 if op==1:
  for i in 0..<10:if a[i+2]!=0:return -1
  if a[12]!=255 or a[13]!=255:return -1
 let needed=if op==0:16 else:4
 if out==nil or cap<csize_t(needed):return -2
 if op==0:
  for i in 0..<10:out[i]=0
  out[10]=255;out[11]=255
  for i in 0..<4:out[12+i]=uint8(a[2+i])
 else:
  for i in 0..<4:out[i]=uint8(a[14+i])
 int64(needed)
