const Bad = -1.0e300
proc half_wave_rectifier*(a:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"half_wave_rectifier".}=
 if a==nil or n!=5:return Bad
 for i in 1..<5:if a[i]< -1_000_000 or a[i]>1_000_000:return Bad
 case a[0]
 of 0:
  if a[1]<0 or a[2]<0 or a[3]<0 or (a[1]==0 and a[2]==0 and a[3]==0):return Bad
  float64(a[4])/float64(a[1]+a[2]+a[3])
 of 1,2:
  if a[2]!=0 or a[3]!=0 or a[4]!=0:return Bad
  float64(a[1])*0.318
 of 3:
  if a[2]<=0 or a[3]!=0 or a[4]!=0:return Bad
  float64(a[1])/float64(a[2])
 of 4,5:
  if a[2]!=0 or a[3]!=0 or a[4]!=0:return Bad
  float64(a[1])/2.0
 else:Bad
