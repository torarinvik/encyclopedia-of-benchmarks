import std/math
proc lorentz_transformation_four_vector(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"lorentz_transformation_four_vector".}=
 if n!=6:return -1e300
 let vel=v[0];let s=v[1];let t=v[2];let x=v[3];let y=v[4];let z=v[5]
 if vel<1 or vel>200000000 or s<0 or s>3 or t< -1000000 or t>1000000 or x< -100000000 or x>100000000 or y< -100000000 or y>100000000 or z< -100000000 or z>100000000:return -1e300
 let b=float64(vel)/299792458.0;let g=1/sqrt(1-b*b);let ct=(float64(t)/1e6)*299792458.0;let xx=float64(x)/100;let yy=float64(y)/100;let zz=float64(z)/100
 let out=[g*ct-g*b*xx,-g*b*ct+g*xx,yy,zz]
 out[int(s)]
