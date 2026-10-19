from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn parse_tree(a:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,off:Int)->Int:
    return 0
@export("same_trees_check")
fn same_trees_check(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>3073:return -1
    let total=Int(n);var p=0
    let n1=a[p];let r1=a[p+1];p+=2
    if n1<0 or n1>1023 or p+3*Int(n1)>total:return -1
    let b1=p;p+=3*Int(n1)
    if p+2>total:return -1
    let n2=a[p];let r2=a[p+1];p+=2
    if n2<0 or n2>1023 or n1+n2>1023 or p+3*Int(n2)!=total:return -1
    let b2=p
    if (n1==0 and r1 != -1) or (n1>0 and (r1<0 or r1>=n1)) or (n2==0 and r2 != -1) or (n2>0 and (r2<0 or r2>=n2)):return -1
    var parent1=InlineArray[Int32,1023]();var parent2=InlineArray[Int32,1023]()
    for t in range(2):
        let cnt=Int(n1 if t==0 else n2);let base=Int(b1 if t==0 else b2);let root=Int(r1 if t==0 else r2)
        for i in range(cnt):
            let v=a[base+3*i];let l=a[base+3*i+1];let r=a[base+3*i+2]
            if v< -2147483648 or v>2147483647 or l< -1 or r< -1 or l>=cnt or r>=cnt:return -1
            if t==0:if l>=0:parent1[Int(l)]+=1;if r>=0:parent1[Int(r)]+=1
            else:if l>=0:parent2[Int(l)]+=1;if r>=0:parent2[Int(r)]+=1
        for i in range(cnt):
            let pc=Int(parent1[i] if t==0 else parent2[i]);if pc != (0 if i==root else 1):return -1
        var seen=InlineArray[Bool,1023]();var q=InlineArray[Int32,1023]();var h=0;var tail=1
        if cnt>0:q[0]=root
        while h<tail:
            let x=Int(q[h]);h+=1;if seen[x]:return -1;seen[x]=True
            let l=a[base+3*x+1];let r=a[base+3*x+2]
            if l>=0:q[tail]=Int32(l);tail+=1
            if r>=0:q[tail]=Int32(r);tail+=1
        if tail!=cnt:return -1
    if n1==0 or n2==0:return 1 if n1==n2 else 0
    var q1=InlineArray[Int32,1023]();var q2=InlineArray[Int32,1023]();var h=0;var tail=1;q1[0]=Int32(r1);q2[0]=Int32(r2)
    while h<tail:
        let x=Int(q1[h]);let y=Int(q2[h]);h+=1;let xbase=Int(b1)+3*x;let ybase=Int(b2)+3*y
        if a[xbase]!=a[ybase] or ((a[xbase+1]== -1)!=(a[ybase+1]== -1)) or ((a[xbase+2]== -1)!=(a[ybase+2]== -1)):return 0
        if a[xbase+1]>=0:q1[tail]=Int32(a[xbase+1]);q2[tail]=Int32(a[ybase+1]);tail+=1
        if a[xbase+2]>=0:q1[tail]=Int32(a[xbase+2]);q2[tail]=Int32(a[ybase+2]);tail+=1
    return 1
