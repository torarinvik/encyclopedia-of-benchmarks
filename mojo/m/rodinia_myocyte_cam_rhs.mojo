# Independent bounded Myocyte CaM reaction model.
# University of Virginia BSD-3-Clause notice and citations are retained in
# benchmarks/m/rodinia_myocyte_cam_rhs/LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rodinia_myocyte_cam_rhs")
fn rodinia_myocyte_cam_rhs(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    let bad=Float64(-1.0e300)
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=22: return bad
    if input[0]<0 or input[0]>100000000 or input[1]<100000000 or input[1]>200000000 or input[2]<500000 or input[2]>5000000: return bad
    for i in range(3,22):
        if input[i]<0 or input[i]>10000000: return bad
    var v=InlineArray[Float32,22](fill=0)
    for i in range(22): v[i]=Float32(input[i])/Float32(1000000)
    let ca=v[0]; let k=Float64(v[1]); let mg=Float64(v[2])
    let btot=v[3]; let camkii=v[4]; let cantot=v[5]; let pp1=v[6]
    let cam=v[7]; let ca2cam=v[8]; let ca4cam=v[9]
    let camb=v[10]; let ca2camb=v[11]; let ca4camb=v[12]
    let pb2=v[13]; let pb=v[14]; let pt=v[15]; let pt2=v[16]; let pa=v[17]
    let ca4can=v[18]; let camcan=v[19]; let ca2camcan=v[20]; let ca4camcan=v[21]
    var kd02=Float32(0); var kd24=Float32(0)
    if mg<=1.0:
        kd02=Float32(0.0025*(1.0+k/0.94-mg/0.012)*(1.0+k/8.1+mg/0.022))
        kd24=Float32(0.128*(1.0+k/0.64+mg/0.0014)*(1.0+k/13.0-mg/0.153))
    else:
        kd02=Float32(0.0025*(1.0+k/0.94-1.0/0.012+(mg-1.0)/0.060)*(1.0+k/8.1+1.0/0.022+(mg-1.0)/0.068))
        kd24=Float32(0.128*(1.0+k/0.64+1.0/0.0014+(mg-1.0)/0.005)*(1.0+k/13.0-1.0/0.153+(mg-1.0)/0.150))
    if kd02<=0 or kd24<=0: return bad
    let k20=Float32(10.0); let k42=Float32(500.0)
    let k02=k20/kd02; let k24=k42/kd24
    let k0boff=Float32(0.0014); let k0bon=Float32(Float64(k0boff)/0.2)
    let k2boff=k0boff/Float32(100); let k20b=k20/Float32(100)
    let kbi=Float32(2.2); let kib=Float32(Float64(kbi)/0.0335)
    let kpp1=Float32(1.72); let kmpp1=Float32(11.5)
    let kb2i=kib*Float32(5); let kb42=Float32(500.0*0.0335/5.0)
    let kta=kbi/Float32(1000); let kt42=Float32(500.0*0.0000335/5.0)
    let kcan0off=Float32(165)* (Float32(2508)*Float32(0.0013))
    let kcan2off=Float32(2508)*Float32(0.0013)
    let ca2=Float64(ca)*Float64(ca)
    let r02=Float32(Float64(k02)*ca2*Float64(cam)-Float64(k20)*Float64(ca2cam))
    let r24=Float32(Float64(k24)*ca2*Float64(ca2cam)-Float64(k42)*Float64(ca4cam))
    let free_b=((btot-camb)-ca2camb)-ca4camb
    let r02b=Float32(Float64(k02)*ca2*Float64(camb)-Float64(k20b)*Float64(ca2camb))
    let r24b=Float32(Float64(k24)*ca2*Float64(ca2camb)-Float64(k42)*Float64(ca4camb))
    let r0b=k0bon*cam*free_b-k0boff*camb
    let r2b=k0bon*ca2cam*free_b-k2boff*ca2camb
    let r4b=k0bon*ca4cam*free_b-k2boff*ca4camb
    let ca2can=(((cantot-ca4can)-camcan)-ca2camcan)-ca4camcan
    let rca4can=Float32(2.0*ca2*Float64(ca2can)-Float64(ca4can))
    let r02can=Float32(Float64(k02)*ca2*Float64(camcan)-Float64(k20/Float32(165))*Float64(ca2camcan))
    let r24can=Float32(Float64(k24)*ca2*Float64(ca2camcan)-Float64(k20/Float32(2508))*Float64(ca4camcan))
    let r0can=Float32(46)*cam*ca4can-kcan0off*camcan
    let r2can=Float32(46)*ca2cam*ca4can-kcan2off*ca2camcan
    let r4can=Float32(46)*ca4cam*ca4can-Float32(0.0013)*ca4camcan
    let pix=((((Float32(1)-pb2)-pb)-pt)-pt2)-pa
    let rib2=kib*ca2cam*pix-kb2i*pb2
    let rb2b=Float32(Float64(k24)*ca2*Float64(pb2)-Float64(kb42)*Float64(pb))
    let rib=kib*ca4cam*pix-kbi*pb
    let t=((pb+pt)+pt2)+pa
    let kbt=Float32(0.055*Float64(t)+0.0074*Float64(t)*Float64(t)+0.015*Float64(t)*Float64(t)*Float64(t))
    let rbt=kbt*pb-(kpp1*pp1*pt)/(kmpp1+camkii*pt)
    let rtt2=kt42*pt-Float32(Float64(k24)*ca2*Float64(pt2))
    let rta=kta*pt-kib*ca4cam*pa
    let rt2a=kb2i*pt2-kib*ca2cam*pa
    let rt2b2=kpp1*pp1*pt2/(kmpp1+camkii*pt2)
    let rai=kpp1*pp1*pa/(kmpp1+camkii*pa)
    var d=InlineArray[Float32,16](fill=0)
    d[0]=Float32(0.001*Float64((-r02-r0b)-r0can))
    d[1]=Float32(0.001*Float64((((r02-r24)-r2b)-r2can)+camkii*(-rib2+rt2a)))
    d[2]=Float32(0.001*Float64(((r24-r4b)-r4can)+camkii*(-rib+rta)))
    d[3]=Float32(0.001*Float64(r0b-r02b))
    d[4]=Float32(0.001*Float64((r02b+r2b)-r24b))
    d[5]=Float32(0.001*Float64(r24b+r4b))
    d[6]=Float32(0.001*Float64((rib2-rb2b)+rt2b2))
    d[7]=Float32(0.001*Float64((rib+rb2b)-rbt))
    d[8]=Float32(0.001*Float64((rbt-rta)-rtt2))
    d[9]=Float32(0.001*Float64((rtt2-rt2a)-rt2b2))
    d[10]=Float32(0.001*Float64((rta+rt2a)-rai))
    d[11]=Float32(0.001*Float64(((rca4can-r0can)-r2can)-r4can))
    d[12]=Float32(0.001*Float64(r0can-r02can))
    d[13]=Float32(0.001*Float64((r2can+r02can)+r24can))
    d[14]=Float32(0.001*Float64(r4can+r24can))
    let communication=((((((r02+r24)+r02b)+r24b)+rca4can)+r02can)+r24can)
    d[15]=Float32(0.001*Float64(Float32(2)*camkii*(rtt2-rb2b)-Float32(2)*communication))
    var result=Float64(0)
    for i in range(16): result+=Float64(i+1)*Float64(d[i])
    return result
