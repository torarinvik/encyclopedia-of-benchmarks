## Copyright (c) 2013 Argonne National Laboratory
##
## Permission is hereby granted, free of charge, to any person obtaining a copy of
## this software and associated documentation files (the "Software"), to deal in
## the Software without restriction, including without limitation the rights to
## use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
## the Software, and to permit persons to whom the Software is furnished to do so,
## subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
## FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
## COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
## IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##
## Clean-room bounded adaptation of RSBench's Doppler-broadened microscopic lookup.
import std/math

const InvalidResult = -1e300
const ScaleQ = 1_000_000.0
type Cpx = object
  re, im: float64

proc cadd(a,b:Cpx):Cpx = Cpx(re:a.re+b.re,im:a.im+b.im)
proc csub(a,b:Cpx):Cpx = Cpx(re:a.re-b.re,im:a.im-b.im)
proc cscale(a:Cpx,x:float64):Cpx = Cpx(re:a.re*x,im:a.im*x)
proc cmul(a,b:Cpx):Cpx = Cpx(re:a.re*b.re-a.im*b.im,im:a.re*b.im+a.im*b.re)
proc cdiv(a,b:Cpx):Cpx =
  let denominator=b.re*b.re+b.im*b.im
  Cpx(re:(a.re*b.re+a.im*b.im)/denominator,im:(a.im*b.re-a.re*b.im)/denominator)

proc fastW(z:Cpx):Cpx =
  const an=[2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04]
  const signs=[-1.0,1.0,-1.0,1.0,-1.0,1.0,-1.0,1.0,-1.0,1.0]
  const denLeft=[9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02]
  if sqrt(z.re*z.re+z.im*z.im)<6.0:
    let magnitude=exp(-12.0*z.im)
    let angle=12.0*z.re
    let e=Cpx(re:magnitude*cos(angle),im:magnitude*sin(angle))
    var w=cdiv(cmul(Cpx(re:0.0,im:1.0),csub(Cpx(re:1.0,im:0.0),e)),cscale(z,12.0))
    var total=Cpx(re:0.0,im:0.0)
    for n in 0..<10:
      let top=csub(cscale(e,signs[n]),Cpx(re:1.0,im:0.0))
      let z2scaled=cmul(cscale(z,144.0),z)
      let bottom=csub(Cpx(re:denLeft[n],im:0.0),z2scaled)
      total=cadd(total,cscale(cdiv(top,bottom),an[n]))
    return cadd(w,cmul(cmul(Cpx(re:0.0,im:8.124330e+01),z),total))
  const a=0.512424224754768462984202823134979415014943561548661637413182
  const b=0.275255128608410950901357962647054304017026259671664935783653
  const c=0.051765358792987823963876628425793170829107067780337219430904
  const d=2.724744871391589049098642037352945695982973740328335064216346
  let z2=cmul(z,z)
  let left=cdiv(Cpx(re:a,im:0.0),csub(z2,Cpx(re:b,im:0.0)))
  let right=cdiv(Cpx(re:c,im:0.0),csub(z2,Cpx(re:d,im:0.0)))
  cmul(cmul(Cpx(re:0.0,im:1.0),z),cadd(left,right))

proc doe_rsbench_doppler_xs*(input:ptr UncheckedArray[int64],length:csize_t):float64 {.cdecl,exportc:"doe_rsbench_doppler_xs".}=
  if input.isNil or length<10 or length>100:return InvalidResult
  let nwRaw=input[0];let npRaw=input[1];let nlRaw=input[2];let energyRaw=input[3]
  if nwRaw<1 or nwRaw>4 or npRaw<0 or npRaw>8 or nlRaw<1 or nlRaw>4 or energyRaw<0 or energyRaw>1_000_000:return InvalidResult
  let nw=int(nwRaw);let np=int(npRaw);let nl=int(nlRaw)
  let factorBase=4+nw*5;let poleBase=factorBase+nl
  if int(length)!=poleBase+np*9:return InvalidResult
  let energy=float64(energyRaw)/ScaleQ
  var bgT,bgA,bgF:array[4,float64]
  var starts,ends:array[4,int]
  for i in 0..<nw:
    let at=4+i*5
    if input[at]<0 or input[at]>1_000_000 or input[at+1]<0 or input[at+1]>1_000_000 or input[at+2]<0 or input[at+2]>1_000_000 or input[at+3]<0 or input[at+3]>npRaw or input[at+4]<input[at+3] or input[at+4]>npRaw:return InvalidResult
    bgT[i]=float64(input[at])/ScaleQ;bgA[i]=float64(input[at+1])/ScaleQ;bgF[i]=float64(input[at+2])/ScaleQ
    starts[i]=int(input[at+3]);ends[i]=int(input[at+4])
  var pseudo:array[4,float64]
  var factors:array[4,Cpx]
  for i in 0..<nl:
    let raw=input[factorBase+i]
    if raw<0 or raw>1_000_000:return InvalidResult
    pseudo[i]=float64(raw)/ScaleQ
  for i in 0..<np:
    let at=poleBase+i*9
    for j in 0..<8:
      if input[at+j]<0 or input[at+j]>152_500_000:return InvalidResult
    if input[at+8]<0 or input[at+8]>=int64(nl):return InvalidResult
  let spacing=1.0/float64(nw)
  var window=int(energy/spacing)
  if window==nw:dec window
  if window<0 or window>=nw:return InvalidResult
  let rootEnergy=sqrt(energy)
  for i in 0..<nl:
    var phi=pseudo[i]*rootEnergy
    if i==1:phi-= -arctan(phi)
    elif i==2:phi-=arctan(3.0*phi/(3.0-phi*phi))
    elif i==3:phi-=arctan(phi*(15.0-phi*phi)/(15.0-6.0*phi*phi))
    phi*=2.0;factors[i]=Cpx(re:cos(phi),im: -sin(phi))
  var sigT=energy*bgT[window];var sigA=energy*bgA[window];var sigF=energy*bgF[window]
  for i in starts[window]..<ends[window]:
    let at=poleBase+i*9
    let ea=Cpx(re:float64(input[at])/ScaleQ,im:float64(input[at+1])/ScaleQ)
    let rt=Cpx(re:float64(input[at+2])/ScaleQ,im:float64(input[at+3])/ScaleQ)
    let ra=Cpx(re:float64(input[at+4])/ScaleQ,im:float64(input[at+5])/ScaleQ)
    let rf=Cpx(re:float64(input[at+6])/ScaleQ,im:float64(input[at+7])/ScaleQ)
    let lv=int(input[at+8]);let z=cscale(csub(Cpx(re:energy,im:0.0),ea),0.5)
    if z.re==0.0 and z.im==0.0:return InvalidResult
    let w=fastW(z)
    sigT+=cmul(cmul(rt,w),factors[lv]).re;sigA+=cmul(ra,w).re;sigF+=cmul(rf,w).re
  let sigE=sigT-sigA
  let result=sigT+2.0*sigA+3.0*sigF+5.0*sigE
  if classify(result) in {fcNan,fcInf,fcNegInf}:return InvalidResult
  result
