proc roundScaled(a,b:int64):int64 =
 let q=(abs(a)*100000+b div 2) div b
 if a<0: -q else: q
proc least_square_approx*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"least_square_approx".}=
 if n<5 or n>13:return -1
 let k=v[0]
 if k<2 or k>6 or n!=1+2*k:return -1
 var sx,sy,sxx,sxy:int64
 for i in 0..<k:
  let x=v[1+2*i];let y=v[2+2*i]
  if x < -20 or x>20 or y < -20 or y>20:return -1
  sx+=x;sy+=y;sxx+=x*x;sxy+=x*y
 let den=k*sxx-sx*sx
 if den<=0:return -1
 let num=k*sxy-sx*sy
 let slope=roundScaled(num,den);let intercept=roundScaled(sy*den-num*sx,k*den)
 if slope<= -100000001 or slope>=100000001 or intercept<= -100000001 or intercept>=100000001:return -1
 (slope+100000001)*200000003+(intercept+100000001)
