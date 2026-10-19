from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn st2_setcol(t:UnsafePointer[Int64,MutAnyOrigin],rn:Int,base:Int,col:Int,value:Int64):
    var node=base+col;t[rn*64+node]=value;node/=2
    while node>0:t[rn*64+node]=t[rn*64+2*node]+t[rn*64+2*node+1];node/=2
fn st2_qcol(t:UnsafePointer[Int64,MutAnyOrigin],rn:Int,base:Int,left:Int,right:Int)->Int64:
    var l=left+base;var r=right+base;var sum:Int64=0
    while l<r:
        if l%2==1:sum+=t[rn*64+l];l+=1
        if r%2==1:r-=1;sum+=t[rn*64+r]
        l/=2;r/=2
    return sum
fn st2_assign(t:UnsafePointer[Int64,MutAnyOrigin],rb:Int,cb:Int,row:Int,col:Int,value:Int64):
    let leaf=rb+row;st2_setcol(t,leaf,cb,col,value);var rn=leaf/2
    while rn>0:
        st2_setcol(t,rn,cb,col,t[(rn*2)*64+cb+col]+t[(rn*2+1)*64+cb+col]);rn/=2
fn st2_query(t:UnsafePointer[Int64,MutAnyOrigin],rb:Int,cb:Int,top:Int,bottom:Int,left:Int,right:Int)->Int64:
    var l=top+rb;var r=bottom+rb;var sum:Int64=0
    while l<r:
        if l%2==1:sum+=st2_qcol(t,l,cb,left,right);l+=1
        if r%2==1:r-=1;sum+=st2_qcol(t,r,cb,left,right)
        l/=2;r/=2
    return sum
@export("segment_tree2_d_benchmark")
fn segment_tree2_d_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1284:return -1
    let rows=a[0];let cols=a[1];let ops=a[2]
    if rows<1 or rows>16 or cols<1 or cols>16 or ops<0 or ops>256 or n!=c_size_t(3+5*ops) or n>1283:return -1
    var rb=1;while rb<Int(rows):rb*=2
    var cb=1;while cb<Int(cols):cb*=2
    var tree=InlineArray[Int64,4096]();var checksum:Int64=0
    for i in range(Int(ops)):
        let b=3+5*i;let op=a[b];let x=a[b+1];let y=a[b+2];let z=a[b+3];let w=a[b+4]
        if op==0:
            if x<0 or x>=rows or y<0 or y>=cols or z< -1000 or z>1000 or w!=0:return -1
            st2_assign(tree.unsafe_ptr(),rb,cb,Int(x),Int(y),z)
        elif op==1:
            if x<0 or x>y or y>rows or z<0 or z>w or w>cols:return -1
            let result=st2_query(tree.unsafe_ptr(),rb,cb,Int(x),Int(y),Int(z),Int(w));checksum+=(i+1)*(result+256001)
        else:return -1
    return checksum
