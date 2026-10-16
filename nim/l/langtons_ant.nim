proc langtons_ant*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"langtons_ant".}=
 if v.isNil or n!=1 or v[0]<0 or v[0]>6:return -1
 var b:array[25,bool];for i in 0..<25:b[i]=true
 var x=2;var y=2;var d=3;let dx=[-1,0,1,0];let dy=[0,1,0,-1]
 for s in 0..<v[0]:
  let old=x*5+y
  if b[old]:d=(d+1) mod 4 else:d=(d+3) mod 4
  x+=dx[d];y+=dy[d];b[old]=not b[old]
 var mask=0'i64
 for i in 0..<25:if not b[i]:mask=mask or (1'i64 shl i)
 mask or ((x*5+y) shl 25) or (d shl 30)
