from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("simulated_annealing")
fn simulated_annealing(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<13 or n>366:return -1
    let x0=a[0];let y0=a[1];let step=a[2];let lx=a[3];let hx=a[4];let ly=a[5];let hy=a[6];let fm=a[7]
    let sr=a[8];let rr=a[9];let tr=a[10];let sc=a[11]
    if x0< -16 or x0>16 or y0< -16 or y0>16 or step<1 or step>4 or lx< -16 or hx>16 or lx>hx or ly< -16 or hy>16 or ly>hy or x0<lx or x0>hx or y0<ly or y0>hy or (fm!=0 and fm!=1) or sr<1000000 or sr>10000000 or rr<100000 or rr>500000 or tr<1000000 or tr>9999999 or tr>=sr or sc<0 or sc>176 or sc>Int64(n)-13:return -1
    let aci=12+Int(sc);let ac=a[aci]
    if ac<0 or ac>176 or n!=c_size_t(13+sc+ac):return -1
    for j in range(Int(sc)):if a[12+j]<0 or a[12+j]>7:return -1
    for j in range(Int(ac)):let v=a[aci+1+j];if v!=0 and v!=999999:return -1
    var temp=Float64(sr)/1000000.0;let rate=Float64(rr)/1000000.0;let threshold=Float64(tr)/1000000.0
    var cx=x0;var cy=y0;var bx=x0;var by=y0;var best=x0*x0+y0*y0;var si=0;var ai=0;var stopped=false
    for _ in range(22):
        let score=cx*cx+cy*cy;if score>best:best=score;bx=cx;by=cy
        var nx=InlineArray[Int64,8]();var ny=InlineArray[Int64,8]()
        nx[0]=cx-step;nx[1]=cx-step;nx[2]=cx-step;nx[3]=cx;nx[4]=cx;nx[5]=cx+step;nx[6]=cx+step;nx[7]=cx+step
        ny[0]=cy-step;ny[1]=cy;ny[2]=cy+step;ny[3]=cy-step;ny[4]=cy+step;ny[5]=cy-step;ny[6]=cy;ny[7]=cy+step
        var rem=8;var found=false;var tx:Int64=0;var ty:Int64=0
        while not found and rem>0:
            if si>=Int(sc):return -1
            let rank=Int(a[12+si]);si+=1;if rank>=rem:return -1
            let xx=nx[rank];let yy=ny[rank];let raw=xx*xx+yy*yy-score
            for k in range(rank+1,rem):nx[k-1]=nx[k];ny[k-1]=ny[k]
            rem-=1
            if xx<lx or xx>hx or yy<ly or yy>hy:continue
            let change=raw if fm==1 else -raw
            if change>0:found=true
            else:
                if ai>=Int(ac):return -1
                let draw=a[aci+1+ai];ai+=1
                if change==0 or draw==0:found=true
            if found:tx=xx;ty=yy
        temp=temp-temp*rate
        if temp<threshold or not found:stopped=true;break
        cx=tx;cy=ty
    if not stopped:return -1
    return (bx+16)*33+(by+16)
