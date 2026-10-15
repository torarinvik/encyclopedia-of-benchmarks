import std/math
const Epsilon=1.0e-7
const MinWidth=2.0e-7
proc objective(id:int,x:float64):float64 =
  if id==0:(x-2.0)*(x-2.0) else:cos(x)
proc golden_search_extrema*(objectiveId,left,right:float64):float64 {.cdecl,exportc:"golden_search_extrema".} =
  if objectiveId!=0.0 and objectiveId!=1.0:return -1.0
  if objectiveId==0.0 and (not (left>=0.0 and left<=4.0) or not (right>=0.0 and right<=4.0)):return -1.0
  if objectiveId==1.0 and (not (left>=2.0 and left<=4.0) or not (right>=2.0 and right<=4.0)):return -1.0
  var a=left;var b=right;if a>b:swap(a,b)
  let id=int(objectiveId);let extremum=if id==0:2.0 else:PI
  if b-a<MinWidth or not (a<extremum and extremum<b):return -1.0
  var mean=Inf;var previousMean=Inf;let phi=1.61803400516510009765625
  for iteration in 0..<128:
    if abs(b-a)<=Epsilon:break
    previousMean=mean;let ratio=(b-a)/phi;let c=b-ratio;let d=a+ratio
    if objective(id,c)<objective(id,d):b=d else:a=c
    mean=(a+b)/2.0
  previousMean
