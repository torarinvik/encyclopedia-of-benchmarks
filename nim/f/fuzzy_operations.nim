proc putd(o:ptr UncheckedArray[uint8],p:int,x:float64)=
 let b=cast[uint64](x)
 for k in 0..<8:o[p+k]=uint8((b shr (8*k)) and 255)
proc fuzzy_operations*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"fuzzy_operations".}=
 if v==nil or n!=8:return -1
 let op=v[0]
 if op<0 or op>3:return -1
 for i in 1..<8:if v[i]<0 or v[i]>1000:return -1
 if op==0:
  for i in 4..<8:if v[i]!=0:return -1
 elif op==1 or op==2:
  if v[7]!=0:return -1
 else:
  if v[4]!=0 or v[5]!=0 or v[6]!=0 or not(v[1]<v[2] and v[2]<v[3]):return -1
 let size=if op==3:8 else:24
 if o==nil or cap<size:return -2
 let a=float64(v[1])/1000.0;let b=float64(v[2])/1000.0;let c=float64(v[3])/1000.0
 case op
 of 0:putd(o,0,1.0-c);putd(o,8,1.0-a);putd(o,16,1.0-b);24
 of 1:putd(o,0,max(a,float64(v[4])/1000.0));putd(o,8,min(c,float64(v[6])/1000.0));putd(o,16,(b+float64(v[5])/1000.0)/2.0);24
 of 2:putd(o,0,min(a,float64(v[4])/1000.0));putd(o,8,(b+float64(v[5])/1000.0)/2.0);putd(o,16,max(c,float64(v[6])/1000.0));24
 else:
  let x=float64(v[7])/1000.0
  let y=if x<=a or x>=c:0.0 elif x<=b:(x-a)/(b-a) else:(c-x)/(c-b)
  putd(o,0,y);8
