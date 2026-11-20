from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_LEN = 32
const MAX_BLOCKS = 16
const MAX_WORDS = 114
const MAX_BYTES = 912
const MAX_INPUT = 68

fn block_hash(data: InlineArray[Int64, MAX_LEN], start: Int, width: Int) -> Int64:
    var value: Int64 = 0
    for i in range(width): value = value * 257 + data[start+i] + 1
    return value

fn suffix_cmp(h: InlineArray[Int64, MAX_BLOCKS], count: Int, a0: Int, b0: Int) -> Int:
    var a = a0
    var b = b0
    while a < count and b < count:
        if h[a] != h[b]: return -1 if h[a] < h[b] else 1
        a += 1
        b += 1
    if a == count and b == count: return 0
    return -1 if a == count else 1

fn prefix_cmp(h: InlineArray[Int64, MAX_BLOCKS], count: Int, suffix: Int,
              query: InlineArray[Int64, MAX_BLOCKS], depth: Int) -> Int:
    for i in range(depth):
        if suffix + i >= count: return -1
        if h[suffix+i] != query[i]: return -1 if h[suffix+i] < query[i] else 1
    return 0

fn prefix_interval(sa: InlineArray[Int, MAX_BLOCKS], count: Int,
    h: InlineArray[Int64, MAX_BLOCKS], query: InlineArray[Int64, MAX_BLOCKS], depth: Int) -> InlineArray[Int, 2]:
    var lo = 0
    var hi = count
    while lo < hi:
        let mid = lo + (hi-lo)//2
        if prefix_cmp(h,count,sa[mid],query,depth) < 0: lo = mid+1
        else: hi = mid
    let first = lo
    hi = count
    while lo < hi:
        let mid = lo + (hi-lo)//2
        if prefix_cmp(h,count,sa[mid],query,depth) <= 0: lo = mid+1
        else: hi = mid
    var result = InlineArray[Int, 2](fill=0)
    result[0] = first
    result[1] = lo
    return result

fn best_depth(sa: InlineArray[Int, MAX_BLOCKS], count: Int,
    h: InlineArray[Int64, MAX_BLOCKS], query: InlineArray[Int64, MAX_BLOCKS], qcount: Int) -> Int:
    var lo = 0
    var hi = min(count,qcount)+1
    while lo+1 < hi:
        let mid = lo+(hi-lo)//2
        let bounds = prefix_interval(sa,count,h,query,mid)
        if bounds[0] < bounds[1]: lo=mid
        else: hi=mid
    return lo

fn extend_match(ref: InlineArray[Int64, MAX_LEN], m: Int, ver: InlineArray[Int64, MAX_LEN],
    n: Int, source0: Int, target0: Int, floor: Int) -> InlineArray[Int, 3]:
    var source=source0
    var target=target0
    var length=0
    while source+length<m and target+length<n and ref[source+length]==ver[target+length]: length+=1
    while source>0 and target>floor and ref[source-1]==ver[target-1]:
        source-=1
        target-=1
        length+=1
    var result = InlineArray[Int, 3](fill=0)
    result[0]=source
    result[1]=target
    result[2]=length
    return result

fn better(a: InlineArray[Int, 3], b: InlineArray[Int, 3]) -> Bool:
    return a[2]>b[2] or (a[2]==b[2] and (a[1]<b[1] or (a[1]==b[1] and a[0]<b[0])))

fn find_at(ref: InlineArray[Int64, MAX_LEN], m: Int, ver: InlineArray[Int64, MAX_LEN], n: Int,
    p: Int, sa: InlineArray[Int, MAX_BLOCKS], count: Int, hashes: InlineArray[Int64, MAX_BLOCKS],
    target: Int, floor: Int) -> InlineArray[Int, 3]:
    var none = InlineArray[Int, 3](fill=0)
    let qcount = (n-target)//p
    if qcount==0 or count==0: return none
    var query = InlineArray[Int64, MAX_BLOCKS](fill=0)
    for i in range(qcount): query[i]=block_hash(ver,target+i*p,p)
    let depth=best_depth(sa,count,hashes,query,qcount)
    if depth==0: return none
    let bounds=prefix_interval(sa,count,hashes,query,max(1,depth-1))
    var found=false
    var best=none
    for rank in range(bounds[0],bounds[1]):
        let source=sa[rank]*p
        if source+p>m: continue
        let candidate=extend_match(ref,m,ver,n,source,target,floor)
        if candidate[2]<p: continue
        if not found or better(candidate,best):
            found=true
            best=candidate
    return best

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for b in range(8): output[offset+b]=UInt8((bits >> (8*b)) & 255)

@export("hsadelta_differential_compression")
fn hsadelta_differential_compression(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT: return -1
    let mv=input[0]
    let nv=input[1]
    let pv=input[2]
    if mv<0 or mv>MAX_LEN or nv<0 or nv>MAX_LEN or pv<2 or pv>4: return -1
    let m=Int(mv)
    let n=Int(nv)
    let p=Int(pv)
    if length != c_size_t(3+m+n): return -1
    var ref=InlineArray[Int64,MAX_LEN](fill=0)
    var ver=InlineArray[Int64,MAX_LEN](fill=0)
    for i in range(m):
        if input[3+i]<0 or input[3+i]>255: return -1
        ref[i]=input[3+i]
    for i in range(n):
        if input[3+m+i]<0 or input[3+m+i]>255: return -1
        ver[i]=input[3+m+i]
    var hashes=InlineArray[Int64,MAX_BLOCKS](fill=0)
    var sa=InlineArray[Int,MAX_BLOCKS](fill=0)
    let count=if m>=p: (m-p)//p+1 else: 0
    for i in range(count):
        hashes[i]=block_hash(ref,i*p,p)
        sa[i]=i
    for i in range(1,count):
        let value=sa[i]
        var j=i
        while j>0 and (suffix_cmp(hashes,count,value,sa[j-1])<0 or
            (suffix_cmp(hashes,count,value,sa[j-1])==0 and value<sa[j-1])):
            sa[j]=sa[j-1]
            j-=1
        sa[j]=value

    var tokens=InlineArray[Int64,MAX_WORDS](fill=0)
    var words=0
    var cursor=0
    var consumed=0
    while cursor+p<=n:
        var found=false
        var best=InlineArray[Int,3](fill=0)
        let scan_end=min(cursor+p-1,n-p)
        for target in range(cursor,scan_end+1):
            let candidate=find_at(ref,m,ver,n,p,sa,count,hashes,target,consumed)
            if candidate[2]>0 and (not found or better(candidate,best)):
                found=true
                best=candidate
        if not found:
            cursor+=1
            continue
        if best[1]>consumed:
            tokens[words]=0; words+=1
            tokens[words]=Int64(best[1]-consumed); words+=1
            for i in range(consumed,best[1]): tokens[words]=ver[i]; words+=1
        tokens[words]=1; words+=1
        tokens[words]=Int64(best[0]); words+=1
        tokens[words]=Int64(best[2]); words+=1
        consumed=best[1]+best[2]
        cursor=consumed
    if consumed<n:
        tokens[words]=0; words+=1
        tokens[words]=Int64(n-consumed); words+=1
        for i in range(consumed,n): tokens[words]=ver[i]; words+=1
    let required=words*8
    if required>0 and (output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required)): return -2
    for i in range(words): store_i64(output,8*i,tokens[i])
    return Int64(required)
