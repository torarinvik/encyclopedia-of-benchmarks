import math
proc puti(o:ptr UncheckedArray[uint8],x:int64)=
 let b=cast[uint64](x)
 for k in 0..<8:o[k]=uint8((b shr (8*k)) and 255)
proc naive_bayes*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"naive_bayes".}=
 if v==nil or n<6:return -1
 let nr=v[0];let f=v[1]
 if nr<2 or nr>8 or f<1 or f>3 or n!=2+int(nr)*(int(f)+1)+int(f):return -1
 var labels:array[8,int];var order:array[3,int64];var counts:array[3,int];var cc=0;var x:array[8,array[3,float64]];var p=2
 for r in 0..<int(nr):
  let lab=v[p];p+=1
  if lab<0 or lab>2:return -1
  var c=0
  while c<cc and order[c]!=lab:c+=1
  if c==cc:order[cc]=lab;cc+=1
  labels[r]=c;counts[c]+=1
  for j in 0..<int(f):
   let z=v[p];p+=1
   if z < -10000 or z>10000:return -1
   x[r][j]=float64(z)/1000.0
 if cc<2:return -1
 var best=NegInf;var answer=order[0]
 for c in 0..<cc:
  var score=ln(float64(counts[c])/float64(nr))
  for j in 0..<int(f):
   var mean=0.0
   for r in 0..<int(nr):if labels[r]==c:mean+=x[r][j]
   mean/=float64(counts[c]);var variance=0.0
   for r in 0..<int(nr):if labels[r]==c:let d=x[r][j]-mean;variance+=d*d
   variance=max(variance/float64(counts[c]),1e-9)
   let raw=v[p+j]
   if raw < -10000 or raw>10000:return -1
   let q=float64(raw)/1000.0
   score+= -0.5*ln(2.0*PI*variance)-(q-mean)*(q-mean)/(2.0*variance)
  if score>best:best=score;answer=order[c]
 if o==nil or cap<8:return -2
 puti(o,answer);8
