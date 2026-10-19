from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn nb_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):o[p+8*b]=UInt8((u>>(8*b))&255)
@export("multinomial_naive_bayes_classifier")
fn multinomial_naive_bayes_classifier(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>360:return -1
    let fits=Int(v[0]);if fits<1 or fits>2:return -1
    var pos=1;var width=0;var rows=0;var cls=InlineArray[Int64,8](fill=0);var sums=InlineArray[Float64,64](fill=0.0);var totals=InlineArray[Float64,8](fill=0.0);var labs=InlineArray[Int64,16](fill=0);var feats=InlineArray[Int64,128](fill=0)
    for _ in range(fits):
        if pos+2>Int(n):return -1
        let r=Int(v[pos]);let w=Int(v[pos+1]);pos+=2;if r<1 or r>16 or w<1 or w>8 or pos+r+r*w>Int(n):return -1
        rows=r;width=w
        for i in range(8):cls[i]=0;totals[i]=0.0
        for i in range(64):sums[i]=0.0
        for i in range(r):let lab=v[pos];pos+=1;if lab<0 or lab>7:return -1;labs[i]=lab
        for i in range(r*w):let x=v[pos];pos+=1;if x<0 or x>100:return -1;feats[(i//w)*8+i%w]=x
        for i in range(r):
            let c=Int(labs[i]);cls[c]+=1
            for j in range(w):let x=Float64(feats[i*8+j]);sums[c*8+j]+=x;totals[c]+=x
    if pos+2>Int(n):return -1
    let pc=Int(v[pos]);let pw=Int(v[pos+1]);pos+=2;if pc<1 or pc>8 or pw<1 or pw>8 or pw!=width or pos+pc*pw!=Int(n):return -1
    var predx=InlineArray[Int64,64](fill=0)
    for i in range(pc*pw):let x=v[pos];pos+=1;if x<0 or x>100:return -1;predx[(i//pw)*8+i%pw]=x
    var predictions=InlineArray[Int64,8](fill=0)
    for row in range(pc):
        var best=-1.0e300;var second=-1.0e300;var bestlab:Int64=-1
        for c in range(8):
            if cls[c]==0:continue
            var score=log(Float64(cls[c])/Float64(rows));let den=totals[c]+Float64(width)
            for j in range(width):score+=Float64(predx[row*8+j])*log((sums[c*8+j]+1.0)/den)
            if score>best:second=best;best=score;bestlab=Int64(c)
            elif score>second:second=score
        if bestlab<0 or (second!=-1.0e300 and best-second<1e-8):return -1
        predictions[row]=bestlab
    let bytes=(pc+1)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    nb_put(o,0,Int64(pc));for i in range(pc):nb_put(o,8*(i+1),predictions[i])
    return Int64(bytes)
