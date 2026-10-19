fn p68_next(inout indices:InlineArray[Int32,10],length:Int)->Bool:
    var pivot=length-2
    while pivot>=0 and indices[pivot]>=indices[pivot+1]:pivot-=1
    if pivot<0:return False
    var succ=length-1
    while indices[succ]<=indices[pivot]:succ-=1
    let t=indices[pivot];indices[pivot]=indices[succ];indices[succ]=t
    var left=pivot+1;var right=length-1
    while left<right:let x=indices[left];indices[left]=indices[right];indices[right]=x;left+=1;right-=1
    return True
@export("problem68")
fn problem68(gon_side:Int64) abi("C")->Int64:
    if gon_side<3 or gon_side>5:return -1
    let n=Int(gon_side);let length=2*n;var values=InlineArray[Int64,10](fill=0);var cursor=0
    for value in range(n+1,0,-1):values[cursor]=Int64(value);cursor+=1
    for value in range(n+2,2*n+1):values[cursor]=Int64(value);cursor+=1
    var indices=InlineArray[Int32,10](fill=0)
    for i in range(length):indices[i]=Int32(i)
    while True:
        let total=values[indices[0]]+values[indices[1]]+values[indices[2]]
        var magic=True;var minimum=values[indices[0]]
        for line in range(1,n):
            let outer=2*n-1 if line==n-1 else 2*line+1
            let il=2*line;let ir=1 if line==n-1 else 2*line+2
            if values[indices[outer]]+values[indices[il]]+values[indices[ir]]!=total:magic=False
            if values[indices[outer]]<minimum:minimum=values[indices[outer]]
        if magic and values[indices[0]]==minimum:
            var result=Int64(0)
            for line in range(n):
                let outer=0 if line==0 else (2*n-1 if line==n-1 else 2*line+1)
                let il=1 if line==0 else 2*line
                let ir=1 if line==n-1 else (2 if line==0 else 2*line+2)
                let triple0=values[indices[outer]];let triple1=values[indices[il]];let triple2=values[indices[ir]]
                result=result*(100 if triple0>=10 else 10)+triple0
                result=result*(100 if triple1>=10 else 10)+triple1
                result=result*(100 if triple2>=10 else 10)+triple2
            return result
        if !p68_next(indices,length):break
    return -1
