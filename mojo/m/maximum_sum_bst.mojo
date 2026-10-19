from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("maximum_sum_bst")
fn maximum_sum_bst(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>32 or v[0]<0 or v[0]>31 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);var valid=InlineArray[Bool,31](fill=False);var mins=InlineArray[Int64,31](fill=0);var maxs=InlineArray[Int64,31](fill=0);var sums=InlineArray[Int64,31](fill=0);var best=InlineArray[Int64,31](fill=0)
    for i in range(count):
        let x=v[i+1]
        if x< -1 or x>1000000 or (x!= -1 and i>0 and v[(i-1)/2+1]== -1):return -1
    if count==0:return 0
    for rev in range(count):
        let i=count-1-rev;let value=v[i+1]
        if value== -1:valid[i]=True;mins[i]=1000001;maxs[i]= -1;continue
        let l=2*i+1;let r=l+1
        let lv=l>=count or valid[l];let rv=r>=count or valid[r]
        let lmax= -1 if l>=count else maxs[l];let rmin=1000001 if r>=count else mins[r]
        let lmin=1000001 if l>=count else mins[l];let rmax= -1 if r>=count else maxs[r]
        let lsum=0 if l>=count else sums[l];let rsum=0 if r>=count else sums[r]
        let lb=0 if l>=count else best[l];let rb=0 if r>=count else best[r]
        if lv and rv and lmax<value and value<rmin:
            valid[i]=True;mins[i]=lmin if lmin<value else value;maxs[i]=rmax if rmax>value else value;sums[i]=lsum+rsum+value
            best[i]=sums[i] if sums[i]>lb else lb;if rb>best[i]:best[i]=rb
        else:valid[i]=False;best[i]=lb if lb>rb else rb
    return best[0]
