import std/math
proc dimensionality_reduction_lda*(input: ptr UncheckedArray[float64], n: csize_t, output: ptr UncheckedArray[float64], cap: csize_t): int64 {.cdecl, exportc: "dimensionality_reduction_lda".} =
  if input.isNil or n < 16 or input[0] != 2 or input[2] != 2 or input[3] != 1 or input[1] != floor(input[1]) or input[1] < 4 or input[1] > 8: return -1
  let m=int(input[1]);if int(n)!=4+3*m:return -1
  let base=4+2*m
  var x,y:array[8,float64];var means:array[2,array[2,float64]];var counts:array[2,int]
  for i in 0..<m:
    x[i]=input[4+i];y[i]=input[4+m+i];let lab=input[base+i]
    if classify(x[i])==fcNan or classify(x[i])==fcInf or classify(y[i])==fcNan or classify(y[i])==fcInf or abs(x[i])>10000 or abs(y[i])>10000 or (lab!=0 and lab!=1):return -1
    let c=int(lab);counts[c]+=1;means[c][0]+=x[i];means[c][1]+=y[i]
  if counts[0]<2 or counts[1]<2:return -1
  for c in 0..1:means[c][0]/=float64(counts[c]);means[c][1]/=float64(counts[c])
  var a,b,d:float64
  for i in 0..<m:
    let c=int(input[base+i]);let dx=x[i]-means[c][0];let dy=y[i]-means[c][1]
    a+=dx*dx;b+=dx*dy;d+=dy*dy
  a/=float64(m);b/=float64(m);d/=float64(m);let det=a*d-b*b
  if det<=1e-12:return -1
  let dx=means[1][0]-means[0][0];let dy=means[1][1]-means[0][1]
  var w0=(d*dx-b*dy)/det;var w1=(a*dy-b*dx)/det;let norm=sqrt(w0*w0+w1*w1)
  if norm<=1e-12:return -1
  w0/=norm;w1/=norm
  if w0<0 or (abs(w0)<=1e-14 and w1<0):w0 = -w0;w1 = -w1
  if output.isNil or int(cap)<m:return -2
  for i in 0..<m:output[i]=w0*x[i]+w1*y[i]
  int64(m)
