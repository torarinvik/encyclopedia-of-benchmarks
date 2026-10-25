## Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt.
import std/math

const Scale = 1_000_000.0

proc roundAway(value:float64):int64 =
  let scaled=value*1000.0
  if scaled<0.0:return -int64(floor(-scaled+0.5))
  int64(floor(scaled+0.5))

proc rodinia_particlefilter_naive*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"rodinia_particlefilter_naive".} =
  if input.isNil or length<8 or length>35:return -1
  let nRaw=input[0];let samplesRaw=input[1];let offsetRaw=input[2]
  if nRaw<1 or nRaw>4 or samplesRaw<1 or samplesRaw>4:return -1
  let n=int(nRaw);let samples=int(samplesRaw)
  if int(length)!=3+n*(4+samples) or offsetRaw<0 or offsetRaw>=1_000_000 or offsetRaw*nRaw>=1_000_000:return -1
  var x,y,movedX,movedY,weights,cdf,resampledX,resampledY:array[4,float64]
  for i in 0..<n:
    let at=3+i*(4+samples)
    let xRaw=input[at];let yRaw=input[at+1];let nxRaw=input[at+2];let nyRaw=input[at+3]
    if xRaw< -100_000_000 or xRaw>100_000_000 or yRaw< -100_000_000 or yRaw>100_000_000 or nxRaw< -2_000_000 or nxRaw>2_000_000 or nyRaw< -2_000_000 or nyRaw>2_000_000:return -1
    x[i]=float64(xRaw)/Scale;y[i]=float64(yRaw)/Scale
    movedX[i]=x[i]+1.0+5.0*(float64(nxRaw)/Scale);movedY[i]=y[i]-2.0+2.0*(float64(nyRaw)/Scale)
    var likelihoodSum=0.0
    for j in 0..<samples:
      let intensity=input[at+4+j]
      if intensity<0 or intensity>255:return -1
      let foreground=float64(intensity-100);let background=float64(intensity-228)
      likelihoodSum+=(foreground*foreground-background*background)/50.0
    let likelihood=likelihoodSum/float64(samples)
    weights[i]=(1.0/float64(n))*exp(likelihood)
  var weightSum=0.0
  for i in 0..<n:weightSum+=weights[i]
  if weightSum<=0.0 or classify(weightSum) in {fcNan,fcInf,fcNegInf}:return -1
  for i in 0..<n:weights[i]/=weightSum
  var estimateX=0.0;var estimateY=0.0
  for i in 0..<n:estimateX+=movedX[i]*weights[i];estimateY+=movedY[i]*weights[i]
  cdf[0]=weights[0]
  for i in 1..<n:cdf[i]=weights[i]+cdf[i-1]
  let offset=float64(offsetRaw)/Scale
  for i in 0..<n:
    let u=offset+float64(i)/float64(n)
    var selected=n-1
    for j in 0..<n:
      if cdf[j]>=u:selected=j;break
    resampledX[i]=movedX[selected];resampledY[i]=movedY[selected]
  var checksum=roundAway(estimateX)+2*roundAway(estimateY)
  for i in 0..<n:checksum+=int64(2*i+3)*roundAway(resampledX[i])+int64(2*i+4)*roundAway(resampledY[i])
  checksum
