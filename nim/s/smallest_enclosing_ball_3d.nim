{.passC: "-lm".}
type P = object
  x,y,z: float64
type S = object
  c: P
  r: float64
proc sub(a,b:P):P = P(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z)
proc add(a,b:P):P = P(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z)
proc mul(a:P,k:float64):P = P(x:a.x*k,y:a.y*k,z:a.z*k)
proc dot(a,b:P):float64 = a.x*b.x+a.y*b.y+a.z*b.z
proc cross(a,b:P):P = P(x:a.y*b.z-a.z*b.y,y:a.z*b.x-a.x*b.z,z:a.x*b.y-a.y*b.x)
proc det(a,b,c:P):float64 = dot(a,cross(b,c))
proc invalid():S = S(c:P(),r:-1)
proc through(p:openArray[P]):S =
  if p.len==1:return S(c:p[0],r:0)
  if p.len==2:
    let c=mul(add(p[0],p[1]),0.5);let d=sub(p[0],c);return S(c:c,r:sqrt(dot(d,d)))
  if p.len==3:
    let u=sub(p[1],p[0]);let v=sub(p[2],p[0]);let w=cross(u,v);let den=2*dot(w,w)
    if den<1e-24:return invalid()
    let off=mul(add(mul(cross(v,w),dot(u,u)),mul(cross(w,u),dot(v,v))),1/den);let c=add(p[0],off);let d=sub(c,p[0]);return S(c:c,r:sqrt(dot(d,d)))
  if p.len==4:
    let a=mul(sub(p[1],p[0]),2.0);let b=mul(sub(p[2],p[0]),2.0);let c=mul(sub(p[3],p[0]),2.0)
    let qa=dot(p[1],p[1])-dot(p[0],p[0]);let qb=dot(p[2],p[2])-dot(p[0],p[0]);let qc=dot(p[3],p[3])-dot(p[0],p[0]);let d=det(a,b,c)
    if abs(d)<1e-18:return invalid()
    let center=mul(add(add(mul(cross(b,c),qa),mul(cross(c,a),qb)),mul(cross(a,b),qc)),1/d);let delta=sub(center,p[0]);return S(c:center,r:sqrt(dot(delta,delta)))
  invalid()
proc contains(s:S,p:P):bool =
  if s.r<0:return false
  let d=sub(p,s.c);dot(d,d)<=(s.r+1e-10)*(s.r+1e-10)
proc fit(r:array[4,P],m:int):S =
  var best=invalid()
  for mask in 1 ..< (1 shl m):
    var q:array[4,P];var n=0
    for i in 0..<m:
      if (mask and (1 shl i))!=0:q[n]=r[i];inc n
    let s=through(q.toOpenArray(0,n-1));if s.r<0:continue
    var ok=true
    for i in 0..<m:
      if not contains(s,r[i]):ok=false
    if ok and (best.r<0 or s.r<best.r-1e-12):best=s
  best
proc welzl(points:openArray[P],n:int,r:var array[4,P],m:int):S =
  if n==0 or m==4:return fit(r,m)
  let s=welzl(points,n-1,r,m)
  if contains(s,points[n-1]):return s
  r[m]=points[n-1];welzl(points,n-1,r,m+1)
proc smallest_enclosing_ball_3d*(input:ptr UncheckedArray[float64],inputLength:csize_t,output:ptr UncheckedArray[float64],outputCapacity:csize_t):int64 {.cdecl,exportc:"smallest_enclosing_ball_3d".} =
  if input.isNil or inputLength<4 or inputLength>25:return -1
  let raw=input[0];if not raw.classify.isFinite or raw<1 or raw>8 or raw!=floor(raw):return -1
  let n=int(raw);if inputLength!=csize_t(1+3*n):return -1
  var points:array[8,P]
  for i in 0..<n:
    points[i]=P(x:input[1+3*i],y:input[2+3*i],z:input[3+3*i])
    if not points[i].x.classify.isFinite or not points[i].y.classify.isFinite or not points[i].z.classify.isFinite or abs(points[i].x)>10 or abs(points[i].y)>10 or abs(points[i].z)>10:return -1
  for i in 1..<n:
    let v=points[i];var j=i
    while j>0 and (points[j-1].x>v.x or (points[j-1].x==v.x and (points[j-1].y>v.y or (points[j-1].y==v.y and points[j-1].z>v.z)))):points[j]=points[j-1];dec j
    points[j]=v
  var boundary:array[4,P];let s=welzl(points.toOpenArray(0,n-1),n,boundary,0)
  if s.r<0 or not s.r.classify.isFinite:return -1
  if output.isNil or outputCapacity<4:return -2
  output[0]=s.c.x;output[1]=s.c.y;output[2]=s.c.z;output[3]=s.r;4
