import math
proc roundEven(x:float64):int64=
 let f=floor(x);let q=int64(f);let d=x-f
 if d<0.5:q elif d>0.5:q+1 elif (q and 1)==0:q else:q+1
proc rgbhsvconversion*(v:ptr int64,n:uint64):int64 {.cdecl,exportc.}=
 if v==nil or n!=4:return -1
 if v[0]==0:
  if v[1]<0 or v[1]>360000 or v[2]<0 or v[2]>1000 or v[3]<0 or v[3]>1000:return -1
  let h=float64(v[1])/1000.0;let s=float64(v[2])/1000.0;let value=float64(v[3])/1000.0;let c=value*s;let sec=h/60.0;let x=c*(1.0-abs((sec - floor(sec/2.0)*2.0)-1.0));let m=value-c
  var r,g,b:float64
  if sec<=1:r=c+m;g=x+m;b=m elif sec<=2:r=x+m;g=c+m;b=m elif sec<=3:r=m;g=c+m;b=x+m elif sec<=4:r=m;g=x+m;b=c+m elif sec<=5:r=x+m;g=m;b=c+m else:r=c+m;g=m;b=x+m
  return (roundEven(255*r) shl 16) or (roundEven(255*g) shl 8) or roundEven(255*b)
 if v[0]!=1 or v[1]<0 or v[1]>255 or v[2]<0 or v[2]>255 or v[3]<0 or v[3]>255:return -1
 let r=float64(v[1])/255.0;let g=float64(v[2])/255.0;let b=float64(v[3])/255.0;let mx=max(r,max(g,b));let mn=min(r,min(g,b));let c=mx-mn;let s=if mx==0:0.0 else:c/mx
 var h:float64
 if c==0:h=0 elif mx==r:h=60*((g-b)/c) elif mx==g:h=60*(2+(b-r)/c) else:h=60*(4+(r-g)/c)
 h=h+360-floor((h+360)/360.0)*360.0
 let qh=roundEven(h*1000);let qs=roundEven(s*1000000);let qv=roundEven(mx*1000000)
 (qh shl 40) or (qs shl 20) or qv
