fn p551_pow10(k:Int64)->Int64:
    var value=Int64(1)
    for _ in range(Int(k)):value*=10
    return value
fn p551_digitsum(value_in:Int64)->Int64:
    var value=value_in;var sum=Int64(0)
    while value>0:sum+=value%10;value//=10
    return sum
fn p551_state(prefix:Int64,suffix:Int64,inout sp:InlineArray[Int32,32768],inout ss:InlineArray[Int64,32768],inout sh:InlineArray[Int32,32768])->Int:
    let slot0=Int((suffix%32768*31+prefix%32768*17)%32768)
    for probe in range(32768):
        let slot=(slot0+probe)&32767
        if sh[slot]==-2:
            sp[slot]=Int32(prefix);ss[slot]=suffix;sh[slot]=-1
            return slot
        if Int64(sp[slot])==prefix and ss[slot]==suffix:return slot
    return -1
fn p551_add_jump(state:Int,difference:Int64,terms:Int64,k:Int64,inout sh:InlineArray[Int32,32768],inout jd:InlineArray[Int64,131072],inout jt:InlineArray[Int64,131072],inout jk:InlineArray[Int32,131072],inout jnext:InlineArray[Int32,131072],inout jump_count:Int,inout failed:Bool):
    if jump_count>=131072:failed=True;return
    let index=jump_count;jump_count+=1
    jd[index]=difference;jt[index]=terms;jk[index]=Int32(k);jnext[index]=sh[state];sh[state]=Int32(index)
fn p551_compute(inout value:Int64,k:Int64,index:Int64,target:Int64,inout difference_out:Int64,inout terms_out:Int64):
    let start=index;let base=p551_pow10(k);let prefix=p551_digitsum(value//base);var suffix=value%base;var difference=Int64(0)
    var position=index
    while position<target:
        position+=1
        let addend=prefix+p551_digitsum(suffix)
        difference+=addend;suffix+=addend
        if suffix>=base:break
    value+=difference;difference_out=difference;terms_out=position-start
fn p551_next(inout value:Int64,k:Int64,index:Int64,target:Int64,inout sp:InlineArray[Int32,32768],inout ss:InlineArray[Int64,32768],inout sh:InlineArray[Int32,32768],inout jd:InlineArray[Int64,131072],inout jt:InlineArray[Int64,131072],inout jk:InlineArray[Int32,131072],inout jnext:InlineArray[Int32,131072],inout jump_count:Int,inout failed:Bool,inout difference_out:Int64,inout terms_out:Int64):
    let base=p551_pow10(k);let prefix=p551_digitsum(value//base);let suffix=value%base;let max_terms=target-index
    let state=p551_state(prefix,suffix,sp,ss,sh)
    if state<0:failed=True;difference_out=0;terms_out=0;return
    var difference=Int64(0);var terms=Int64(0);var best= -1;var jump=Int(sh[state])
    while jump>=0:
        if Int64(jk[jump])<=k and jt[jump]<=max_terms and (best<0 or jt[jump]>jt[best]):best=jump
        jump=Int(jnext[jump])
    if best>=0:
        difference=jd[best];terms=jt[best];value+=difference
    if terms>=max_terms or suffix+difference>=base:
        difference_out=difference;terms_out=terms;return
    if k>2:
        while !failed:
            var extra=Int64(0);var jumped=Int64(0)
            p551_next(value,k-1,index+terms,target,sp,ss,sh,jd,jt,jk,jnext,jump_count,failed,extra,jumped)
            difference+=extra;terms+=jumped
            if terms>=max_terms or suffix+difference>=base:break
    else:
        var extra=Int64(0);var jumped=Int64(0)
        p551_compute(value,k,index+terms,target,extra,jumped)
        difference+=extra;terms+=jumped
    if !failed and terms<max_terms:p551_add_jump(state,difference,terms,k,sh,jd,jt,jk,jnext,jump_count,failed)
    difference_out=difference;terms_out=terms
@export("problem551")
fn problem551(n:Int64) abi("C")->Int64:
    if n<1 or n>1000000000000000:return -1
    var sp=InlineArray[Int32,32768](fill=0);var ss=InlineArray[Int64,32768](fill=0);var sh=InlineArray[Int32,32768](fill=-2)
    var jd=InlineArray[Int64,131072](fill=0);var jt=InlineArray[Int64,131072](fill=0);var jk=InlineArray[Int32,131072](fill=0);var jnext=InlineArray[Int32,131072](fill=0)
    var jump_count=0;var failed=False;var value=Int64(1);var jumped=Int64(0)
    while jumped!=n-1 and !failed:
        var ignored=Int64(0);var terms=Int64(0)
        p551_next(value,18,1+jumped,n,sp,ss,sh,jd,jt,jk,jnext,jump_count,failed,ignored,terms)
        jumped+=terms
    return -1 if failed else value
