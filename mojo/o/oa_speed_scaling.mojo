from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_JOBS = 2
comptime MAX_INPUT = 8
comptime MAX_OUTPUT = 152
comptime MAX_SEGMENTS = 3

struct OaRat(Copyable):
    var n: Int64
    var d: Int64
    fn __init__(out self, n: Int64, d: Int64):
        self.n = n
        self.d = d

struct OaSegment(Copyable):
    var start: Int64
    var finish: Int64
    var speed_n: Int64
    var speed_d: Int64
    fn __init__(out self):
        self.start = 0
        self.finish = 0
        self.speed_n = 0
        self.speed_d = 1
    fn __init__(out self, start: Int64, finish: Int64, speed_n: Int64, speed_d: Int64):
        self.start = start
        self.finish = finish
        self.speed_n = speed_n
        self.speed_d = speed_d

fn oa_gcd(a: Int64, b: Int64) -> Int64:
    var x = a
    var y = b
    while y != 0:
        let r = x % y
        x = y
        y = r
    if x < 0: return -x
    return x

fn oa_make(n0: Int64, d0: Int64) -> OaRat:
    var n = n0
    var d = d0
    if d < 0:
        n = -n
        d = -d
    let g = oa_gcd(n, d)
    return OaRat(n // g, d // g)

fn oa_int(x: Int64) -> OaRat: return OaRat(x, 1)
fn oa_add(a: OaRat, b: OaRat) -> OaRat: return oa_make(a.n*b.d+b.n*a.d,a.d*b.d)
fn oa_sub(a: OaRat, b: OaRat) -> OaRat: return oa_make(a.n*b.d-b.n*a.d,a.d*b.d)
fn oa_mul(a: OaRat, b: OaRat) -> OaRat: return oa_make(a.n*b.n,a.d*b.d)
fn oa_div(a: OaRat, b: OaRat) -> OaRat: return oa_make(a.n*b.d,a.d*b.n)
fn oa_cmp(a: OaRat, b: OaRat) -> Int:
    let left = a.n*b.d
    let right = b.n*a.d
    if left > right: return 1
    if left < right: return -1
    return 0

fn oa_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset+byte] = UInt8((bits >> (8*byte)) & 255)

fn oa_append_segment(inout segments: InlineArray[OaSegment, MAX_SEGMENTS],
        inout count: Int, start: Int64, finish: Int64, speed: OaRat):
    if finish <= start or speed.n <= 0: return
    if count > 0 and segments[count-1].finish == start and
            oa_cmp(speed,oa_make(segments[count-1].speed_n,segments[count-1].speed_d)) == 0:
        segments[count-1].finish = finish
        return
    segments[count] = OaSegment(start=start, finish=finish,
        speed_n=speed.n, speed_d=speed.d)
    count += 1

@export("oa_speed_scaling")
fn oa_speed_scaling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let count64 = input[0]
    if count64 < 1 or count64 > MAX_JOBS or length != c_size_t(1+3*Int(count64)): return -1
    let n = Int(count64)
    var release = InlineArray[Int64, MAX_JOBS](fill=0)
    var deadline = InlineArray[Int64, MAX_JOBS](fill=0)
    var work = InlineArray[Int64, MAX_JOBS](fill=0)
    var remaining = InlineArray[OaRat, MAX_JOBS](fill=oa_int(0))
    var completion = InlineArray[OaRat, MAX_JOBS](fill=oa_int(0))
    var completed = InlineArray[Bool, MAX_JOBS](fill=False)
    for j in range(n):
        let r = input[1+3*j]
        let d = input[2+3*j]
        let w = input[3+3*j]
        if r < 0 or r >= d or d > 4 or w < 1 or w > 4: return -1
        release[j] = r
        deadline[j] = d
        work[j] = w
    var segments = InlineArray[OaSegment, MAX_SEGMENTS](fill=OaSegment())
    var segment_count = 0
    var energy = oa_int(0)
    for now_index in range(5):
        let now = Int64(now_index)
        var has_arrival = False
        for j in range(n):
            if release[j] == now:
                remaining[j] = oa_int(work[j])
                has_arrival = True
        if not has_arrival: continue
        var next_release: Int64 = 5
        for j in range(n):
            if release[j] > now and release[j] < next_release: next_release = release[j]
        var order = InlineArray[Int, MAX_JOBS](fill=0)
        var used = 0
        for j in range(n):
            if remaining[j].n > 0 and deadline[j] > now:
                order[used] = j
                used += 1
        for i in range(1, used):
            let value = order[i]
            var k = i
            while k > 0 and (deadline[order[k-1]] > deadline[value] or
                    (deadline[order[k-1]] == deadline[value] and order[k-1] > value)):
                order[k] = order[k-1]
                k -= 1
            order[k] = value
        var left = now
        while used > 0:
            var prefix = oa_int(0)
            var best = oa_int(0)
            var best_count = 0
            for k in range(1, used+1):
                prefix = oa_add(prefix,remaining[order[k-1]])
                let density = oa_div(prefix,oa_int(deadline[order[k-1]]-left))
                if best_count == 0 or oa_cmp(density,best) > 0:
                    best = density
                    best_count = k
            let right = deadline[order[best_count-1]]
            let stop = if right < next_release: right else: next_release
            oa_append_segment(segments,segment_count,left,stop,best)
            energy = oa_add(energy,oa_mul(oa_mul(oa_mul(best,best),best),oa_int(stop-left)))
            var cursor = oa_int(left)
            let stop_rat = oa_int(stop)
            for k in range(best_count):
                let j = order[k]
                let finish = oa_add(cursor,oa_div(remaining[j],best))
                if oa_cmp(finish,stop_rat) <= 0:
                    completion[j] = finish
                    completed[j] = True
                    remaining[j] = oa_int(0)
                    cursor = finish
                else:
                    remaining[j] = oa_sub(remaining[j],oa_mul(best,oa_sub(stop_rat,cursor)))
                    cursor = stop_rat
                    break
            if stop < right: break
            for k in range(best_count,used): order[k-best_count] = order[k]
            used -= best_count
            left = right
    for j in range(n):
        if not completed[j]: return -1
    var values = InlineArray[Int64, MAX_OUTPUT/8](fill=0)
    var fields = 0
    values[fields] = Int64(segment_count); fields += 1
    values[fields] = energy.n; values[fields+1] = energy.d; fields += 2
    for s in range(segment_count):
        values[fields] = segments[s].start; values[fields+1] = segments[s].finish; fields += 2
        values[fields] = segments[s].speed_n; values[fields+1] = segments[s].speed_d; fields += 2
    for j in range(n):
        values[fields] = completion[j].n; values[fields+1] = completion[j].d; fields += 2
    let output_bytes = 8*fields
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for i in range(fields): oa_store(output,8*i,values[i])
    return Int64(output_bytes)
