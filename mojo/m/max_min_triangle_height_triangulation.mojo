from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn mt_cross(points: InlineArray[Int64, 10], a: Int, b: Int, c: Int) -> Int64:
    let ax = points[2*a]
    let ay = points[2*a+1]
    let bx = points[2*b]
    let by = points[2*b+1]
    let cx = points[2*c]
    let cy = points[2*c+1]
    return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)

fn mt_gcd(a0: Int64, b0: Int64) -> Int64:
    var a = a0
    var b = b0
    while b != 0:
        let r = a % b
        a = b
        b = r
    return a

fn mt_fraction(num: Int64, den: Int64) -> Tuple[Int64, Int64]:
    let divisor = mt_gcd(num, den)
    return (num // divisor, den // divisor)

fn mt_compare(an: Int64, ad: Int64, bn: Int64, bd: Int64) -> Int:
    let left = an*bd
    let right = bn*ad
    if left < right: return -1
    if left > right: return 1
    return 0

fn mt_triangle_score(points: InlineArray[Int64, 10], n: Int, a: Int, b: Int, c: Int) -> Tuple[Int64, Int64]:
    let pa = a % n
    let pb = b % n
    let pc = c % n
    var area = mt_cross(points, pa, pb, pc)
    if area < 0: area = -area
    let abx = points[2*pa]-points[2*pb]
    let aby = points[2*pa+1]-points[2*pb+1]
    let bcx = points[2*pb]-points[2*pc]
    let bcy = points[2*pb+1]-points[2*pc+1]
    let cax = points[2*pc]-points[2*pa]
    let cay = points[2*pc+1]-points[2*pa+1]
    var best = mt_fraction(area*area, abx*abx+aby*aby)
    var candidate = mt_fraction(area*area, bcx*bcx+bcy*bcy)
    if mt_compare(candidate[0],candidate[1],best[0],best[1]) < 0: best=candidate
    candidate = mt_fraction(area*area, cax*cax+cay*cay)
    if mt_compare(candidate[0],candidate[1],best[0],best[1]) < 0: best=candidate
    return best

fn mt_better(cn: Int64, cd: Int64, cc: Int, bn: Int64, bd: Int64, bc: Int) -> Bool:
    let comparison = mt_compare(cn,cd,bn,bd)
    return comparison > 0 or (comparison == 0 and cc < bc)

fn mt_join(table_num: InlineArray[Int64, 100], table_den: InlineArray[Int64, 100],
           table_count: InlineArray[Int, 100], table_valid: InlineArray[Bool, 100],
           left: Int, right: Int, tn: Int64, td: Int64) -> Tuple[Int64, Int64, Int]:
    var minimum_num = tn
    var minimum_den = td
    var worst_count = 1
    if table_valid[left]:
        let cmp = mt_compare(table_num[left],table_den[left],minimum_num,minimum_den)
        if cmp < 0:
            minimum_num=table_num[left]
            minimum_den=table_den[left]
            worst_count=table_count[left]
        elif cmp == 0:
            worst_count+=table_count[left]
    if table_valid[right]:
        let cmp = mt_compare(table_num[right],table_den[right],minimum_num,minimum_den)
        if cmp < 0:
            minimum_num=table_num[right]
            minimum_den=table_den[right]
            worst_count=table_count[right]
        elif cmp == 0:
            worst_count+=table_count[right]
    return (minimum_num,minimum_den,worst_count)

fn mt_collect(start: Int, finish: Int, table_split: InlineArray[Int, 100], n: Int,
              inout out_a: InlineArray[Int, 3], inout out_b: InlineArray[Int, 3],
              inout out_c: InlineArray[Int, 3], inout count: Int):
    if finish-start < 2: return
    let middle = table_split[start*10+finish]
    out_a[count]=start%n
    out_b[count]=middle%n
    out_c[count]=finish%n
    count+=1
    mt_collect(start,middle,table_split,n,out_a,out_b,out_c,count)
    mt_collect(middle,finish,table_split,n,out_a,out_b,out_c,count)

fn mt_has_edge(a: InlineArray[Int, 3], b: InlineArray[Int, 3], c: InlineArray[Int, 3],
               count: Int, left: Int, right: Int) -> Bool:
    for i in range(count):
        var x=a[i]
        var y=b[i]
        if x>y:
            let temporary=x
            x=y
            y=temporary
        if x==left and y==right: return True
        x=b[i]
        y=c[i]
        if x>y:
            let temporary=x
            x=y
            y=temporary
        if x==left and y==right: return True
        x=c[i]
        y=a[i]
        if x>y:
            let temporary=x
            x=y
            y=temporary
        if x==left and y==right: return True
    return False

fn mt_evaluate(points: InlineArray[Int64, 10], n: Int,
               a: InlineArray[Int, 3], b: InlineArray[Int, 3], c: InlineArray[Int, 3],
               count: Int) -> Tuple[Int64, Int64, Int]:
    let first=mt_triangle_score(points,n,a[0],b[0],c[0])
    var minimum_num=first[0]
    var minimum_den=first[1]
    var worst_count=1
    for i in range(1,count):
        let score=mt_triangle_score(points,n,a[i],b[i],c[i])
        let cmp=mt_compare(score[0],score[1],minimum_num,minimum_den)
        if cmp<0:
            minimum_num=score[0]
            minimum_den=score[1]
            worst_count=1
        elif cmp==0:
            worst_count+=1
    return (minimum_num,minimum_den,worst_count)

fn mt_solve(points: InlineArray[Int64, 10], n: Int) -> Int64:
    var table_num=InlineArray[Int64,100](fill=0)
    var table_den=InlineArray[Int64,100](fill=1)
    var table_count=InlineArray[Int,100](fill=0)
    var table_split=InlineArray[Int,100](fill=0)
    var table_valid=InlineArray[Bool,100](fill=False)
    for span in range(2,n-1):
        for start in range(n):
            let finish=start+span
            var found=False
            var best=(Int64(0),Int64(1),Int(0))
            var best_middle=0
            for middle in range(start+1,finish):
                let triangle=mt_triangle_score(points,n,start,middle,finish)
                let candidate=mt_join(table_num,table_den,table_count,table_valid,
                    start*10+middle,middle*10+finish,triangle[0],triangle[1])
                if not found or mt_better(candidate[0],candidate[1],candidate[2],best[0],best[1],best[2]):
                    found=True
                    best=candidate
                    best_middle=middle
            let index=start*10+finish
            table_num[index]=best[0]
            table_den[index]=best[1]
            table_count[index]=best[2]
            table_valid[index]=True
            table_split[index]=best_middle

    var current_a=InlineArray[Int,3](fill=0)
    var current_b=InlineArray[Int,3](fill=0)
    var current_c=InlineArray[Int,3](fill=0)
    var current_count=n-2
    for middle in range(1,n-1):
        let index=middle-1
        current_a[index]=0
        current_b[index]=middle
        current_c[index]=middle+1
    var current=mt_evaluate(points,n,current_a,current_b,current_c,current_count)
    var improvements=0
    while True:
        var changed=False
        for left in range(n):
            if changed: break
            for right in range(left+2,n):
                if left==0 and right==n-1: continue
                if mt_has_edge(current_a,current_b,current_c,current_count,left,right): continue
                var candidate_a=InlineArray[Int,3](fill=0)
                var candidate_b=InlineArray[Int,3](fill=0)
                var candidate_c=InlineArray[Int,3](fill=0)
                var candidate_count=0
                mt_collect(left,right,table_split,n,candidate_a,candidate_b,candidate_c,candidate_count)
                mt_collect(right,left+n,table_split,n,candidate_a,candidate_b,candidate_c,candidate_count)
                let candidate=mt_evaluate(points,n,candidate_a,candidate_b,candidate_c,candidate_count)
                if mt_better(candidate[0],candidate[1],candidate[2],current[0],current[1],current[2]):
                    for i in range(candidate_count):
                        current_a[i]=candidate_a[i]
                        current_b[i]=candidate_b[i]
                        current_c[i]=candidate_c[i]
                    current_count=candidate_count
                    current=candidate
                    improvements+=1
                    if improvements>30: return -1
                    changed=True
                    break
        if not changed: return current[0]*513+current[1]
    return -1

@export("max_min_triangle_height_triangulation")
fn max_min_triangle_height_triangulation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 12: return -1
    if input[0] < 3 or input[0] > 5: return -1
    let n=Int(input[0])
    if length != c_size_t(1+2*n): return -1
    var points=InlineArray[Int64,10](fill=0)
    for i in range(n):
        let x=input[1+2*i]
        let y=input[2+2*i]
        if x < -8 or x > 8 or y < -8 or y > 8: return -1
        for j in range(i):
            if points[2*j]==x and points[2*j+1]==y: return -1
        points[2*i]=x
        points[2*i+1]=y
    var area2:Int64=0
    for i in range(n):
        let next=(i+1)%n
        area2+=points[2*i]*points[2*next+1]-points[2*i+1]*points[2*next]
    if area2<=0: return -1
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                if mt_cross(points,a,b,c)==0: return -1
    for edge in range(n):
        let next=(edge+1)%n
        for vertex in range(n):
            if vertex!=edge and vertex!=next and mt_cross(points,edge,next,vertex)<=0: return -1
    return mt_solve(points,n)
