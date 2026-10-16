import std/math
const Invalid = -1.0e300
const PiValue = 3.14159265358979323846264338327950288
proc lamberts_ellipsoidal_distance*(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"lamberts_ellipsoidal_distance".}=
 if n!=4:return Invalid
 if v[0]< -90000000 or v[0]>90000000 or v[2]< -90000000 or v[2]>90000000 or v[1]< -180000000 or v[1]>180000000 or v[3]< -180000000 or v[3]>180000000:return Invalid
 if v[0]==v[2] and v[1]==v[3]:return Invalid
 let lat1=float64(v[0])/1e6;let lon1=float64(v[1])/1e6;let lat2=float64(v[2])/1e6;let lon2=float64(v[3])/1e6
 let p1=lat1*PiValue/180;let p2=lat2*PiValue/180;let l1=lon1*PiValue/180;let l2=lon2*PiValue/180
 let h=sqrt(sin((p2-p1)/2)^2+cos(p1)*cos(p2)*sin((l2-l1)/2)^2)
 if h==0:return Invalid
 let sigma=2*arcsin(h);let f=(6378137.0-6356752.314245)/6378137.0
 let b1=arctan((1-f)*tan(lat1*PiValue/180));let b2=arctan((1-f)*tan(lat2*PiValue/180));let p=(b1+b2)/2;let q=(b2-b1)/2
 let x=(sigma-sin(sigma))*((sin(p)^2*cos(q)^2)/(cos(sigma/2)^2))
 let y=(sigma+sin(sigma))*((cos(p)^2*sin(q)^2)/(sin(sigma/2)^2))
 6378137.0*(sigma-(f/2)*(x+y))
