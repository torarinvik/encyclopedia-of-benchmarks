@export("problem91")
fn problem91(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>50:return -1
    var count=Int64(0)
    for x1 in range(Int(limit+1)):
        for y1 in range(Int(limit+1)):
            for x2 in range(x1,Int(limit+1)):
                let begin=y1+1 if x2==x1 else 0
                for y2 in range(begin,Int(limit+1)):
                    if (x1==0 and y1==0) or (x2==0 and y2==0):continue
                    let op=x1*x1+y1*y1;let oq=x2*x2+y2*y2;let pq=(x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)
                    if op+oq==pq or op+pq==oq or oq+pq==op:count+=1
    return count
