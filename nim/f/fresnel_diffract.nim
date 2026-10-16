import std/math
proc fresnel_diffract*(v:ptr UncheckedArray[float64],n:csize_t,outp:ptr UncheckedArray[float64],cap:csize_t):int64 {.cdecl,exportc:"fresnel_diffract".}=
 if v.isNil or n!=12 or v[0]!=4 or v[1]!=1 or v[2]!=1 or v[3]!=16:return -1
 for i in 4..11:
  if classify(v[i]) in {fcNan,fcInf,fcNegInf} or abs(v[i])>100:return -1
 if outp.isNil or cap<8:return -2
 let xr=[v[6],v[7],v[4],v[5]];let xi=[v[10],v[11],v[8],v[9]];let cr=[1.0,0.0,-1.0,0.0];let si=[0.0,-1.0,0.0,1.0]
 var fr,fi:array[4,float64]
 for k in 0..3:
  for j in 0..3:
   let t=(k*j) and 3
   fr[k]+=xr[j]*cr[t]-xi[j]*si[t];fi[k]+=xr[j]*si[t]+xi[j]*cr[t]
 for k in [1,3]:fr[k]= -fr[k];fi[k]= -fi[k]
 var zr,zi:array[4,float64]
 for j in 0..3:
  for k in 0..3:
   let t=(k*j) and 3;let s= -si[t]
   zr[j]+=(fr[k]*cr[t]-fi[k]*s)*0.25;zi[j]+=(fr[k]*s+fi[k]*cr[t])*0.25
 let result=[zr[2],zr[3],zr[0],zr[1],zi[2],zi[3],zi[0],zi[1]]
 for i in 0..7:outp[i]=result[i]
 return 8
