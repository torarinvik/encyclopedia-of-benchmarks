proc kinematics*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "kinematics".} =
  if v.isNil or n!=4:return -1
  let o=v[0];let x=v[1];let y=v[2];let z=v[3]
  if o<0 or o>3 or abs(x)>1000 or abs(y)>1000 or abs(z)>1000:return -1
  if o==0:return 2*x+2*y*z
  if o==1:return 2*x*z+y*z*z
  if o==2:return 2*x*x+4*y*z
  (x+y)*z
