# Independent bounded ParGeo-style profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn bdk_insert(inout levels: InlineArray[Int, 192], inout sizes: InlineArray[Int, 6], id: Int):
    var carry = InlineArray[Int, 32](fill=0)
    carry[0] = id
    var count = 1
    for level in range(6):
        if sizes[level] == 0:
            for i in range(count): levels[32 * level + i] = carry[i]
            sizes[level] = count
            return
        var next = InlineArray[Int, 32](fill=0)
        let prior = sizes[level]
        for i in range(prior): next[i] = levels[32 * level + i]
        for i in range(count): next[prior + i] = carry[i]
        count += prior
        sizes[level] = 0
        carry = next

fn bdk_before(a: Int, b: Int, axis: Int, x: InlineArray[Int, 32], y: InlineArray[Int, 32]) -> Bool:
    let first_a = x[a] if axis == 0 else y[a]
    let first_b = x[b] if axis == 0 else y[b]
    let second_a = y[a] if axis == 0 else x[a]
    let second_b = y[b] if axis == 0 else x[b]
    return first_a < first_b or (first_a == first_b and (second_a < second_b or (second_a == second_b and a < b)))

fn bdk_build(inout ids: InlineArray[Int, 32], begin: Int, end: Int, depth: Int,
             x: InlineArray[Int, 32], y: InlineArray[Int, 32],
             inout left: InlineArray[Int, 32], inout right: InlineArray[Int, 32],
             inout minx: InlineArray[Int, 32], inout maxx: InlineArray[Int, 32],
             inout miny: InlineArray[Int, 32], inout maxy: InlineArray[Int, 32]) -> Int:
    if begin >= end: return -1
    for i in range(begin + 1, end):
        let value = ids[i]
        var j = i
        while j > begin and bdk_before(value, ids[j - 1], depth % 2, x, y):
            ids[j] = ids[j - 1]
            j -= 1
        ids[j] = value
    let middle = (begin + end) // 2
    let id = ids[middle]
    left[id] = bdk_build(ids, begin, middle, depth + 1, x, y, left, right, minx, maxx, miny, maxy)
    right[id] = bdk_build(ids, middle + 1, end, depth + 1, x, y, left, right, minx, maxx, miny, maxy)
    minx[id] = x[id]
    maxx[id] = x[id]
    miny[id] = y[id]
    maxy[id] = y[id]
    for side in range(2):
        let child = left[id] if side == 0 else right[id]
        if child >= 0:
            minx[id] = min(minx[id], minx[child])
            maxx[id] = max(maxx[id], maxx[child])
            miny[id] = min(miny[id], miny[child])
            maxy[id] = max(maxy[id], maxy[child])
    return id

fn bdk_box(id: Int, qx: Int, qy: Int, minx: InlineArray[Int, 32], maxx: InlineArray[Int, 32],
           miny: InlineArray[Int, 32], maxy: InlineArray[Int, 32]) -> Int:
    let dx = max(0, max(minx[id] - qx, qx - maxx[id]))
    let dy = max(0, max(miny[id] - qy, qy - maxy[id]))
    return dx * dx + dy * dy

fn bdk_query(id: Int, qx: Int, qy: Int, x: InlineArray[Int, 32], y: InlineArray[Int, 32],
             active: InlineArray[Bool, 32], left: InlineArray[Int, 32], right: InlineArray[Int, 32],
             minx: InlineArray[Int, 32], maxx: InlineArray[Int, 32],
             miny: InlineArray[Int, 32], maxy: InlineArray[Int, 32], inout best: Int):
    if id < 0: return
    if bdk_box(id, qx, qy, minx, maxx, miny, maxy) > best: return
    if active[id]:
        let dx = x[id] - qx
        let dy = y[id] - qy
        best = min(best, dx * dx + dy * dy)
    var first = left[id]
    var second = right[id]
    if first >= 0 and second >= 0 and bdk_box(second, qx, qy, minx, maxx, miny, maxy) < bdk_box(first, qx, qy, minx, maxx, miny, maxy):
        let temporary = first
        first = second
        second = temporary
    bdk_query(first, qx, qy, x, y, active, left, right, minx, maxx, miny, maxy, best)
    bdk_query(second, qx, qy, x, y, active, left, right, minx, maxx, miny, maxy, best)

@export("batch_dynamic_kd_tree")
fn batch_dynamic_kd_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 250: return -1
    let raw_initial = input[0]
    if raw_initial < 0 or raw_initial > 8 or Int(length) < 2 + 3 * Int(raw_initial): return -1
    var x = InlineArray[Int, 32](fill=0)
    var y = InlineArray[Int, 32](fill=0)
    var used = InlineArray[Bool, 32](fill=False)
    var active = InlineArray[Bool, 32](fill=False)
    var levels = InlineArray[Int, 192](fill=0)
    var sizes = InlineArray[Int, 6](fill=0)
    var answers = InlineArray[Int, 8](fill=0)
    var pos = 1
    var inserted = 0
    for initial in range(Int(raw_initial)):
        let raw_id = input[pos]
        let px = input[pos + 1]
        let py = input[pos + 2]
        pos += 3
        if raw_id < 0 or raw_id >= 32 or px < -1000 or px > 1000 or py < -1000 or py > 1000: return -1
        let id = Int(raw_id)
        if used[id]: return -1
        for j in range(32):
            if active[j] and x[j] == Int(px) and y[j] == Int(py): return -1
        x[id] = Int(px)
        y[id] = Int(py)
        used[id] = True
        active[id] = True
        inserted += 1
        bdk_insert(levels, sizes, id)
    if pos >= Int(length): return -1
    let raw_batches = input[pos]
    pos += 1
    if raw_batches < 1 or raw_batches > 8: return -1
    let batches = Int(raw_batches)
    for batch in range(batches):
        if pos + 2 > Int(length): return -1
        let kind = input[pos]
        let raw_count = input[pos + 1]
        pos += 2
        if (kind != 0 and kind != 1) or raw_count < 1 or raw_count > 8: return -1
        let count = Int(raw_count)
        if kind == 0:
            if inserted + count > 32 or pos + 3 * count + 2 > Int(length): return -1
            for update in range(count):
                let raw_id = input[pos]
                let px = input[pos + 1]
                let py = input[pos + 2]
                pos += 3
                if raw_id < 0 or raw_id >= 32 or px < -1000 or px > 1000 or py < -1000 or py > 1000: return -1
                let id = Int(raw_id)
                if used[id]: return -1
                for j in range(32):
                    if active[j] and x[j] == Int(px) and y[j] == Int(py): return -1
                x[id] = Int(px)
                y[id] = Int(py)
                used[id] = True
                active[id] = True
                inserted += 1
                bdk_insert(levels, sizes, id)
        else:
            if pos + count + 2 > Int(length): return -1
            for update in range(count):
                let raw_id = input[pos]
                pos += 1
                if raw_id < 0 or raw_id >= 32: return -1
                let id = Int(raw_id)
                if not active[id]: return -1
                active[id] = False
        let qx = input[pos]
        let qy = input[pos + 1]
        pos += 2
        if qx < -1000 or qx > 1000 or qy < -1000 or qy > 1000: return -1
        var best = 8000001
        for level in range(6):
            let count_level = sizes[level]
            if count_level == 0: continue
            var ids = InlineArray[Int, 32](fill=0)
            for i in range(count_level): ids[i] = levels[level * 32 + i]
            var left = InlineArray[Int, 32](fill=-1)
            var right = InlineArray[Int, 32](fill=-1)
            var minx = InlineArray[Int, 32](fill=0)
            var maxx = InlineArray[Int, 32](fill=0)
            var miny = InlineArray[Int, 32](fill=0)
            var maxy = InlineArray[Int, 32](fill=0)
            let root = bdk_build(ids, 0, count_level, 0, x, y, left, right, minx, maxx, miny, maxy)
            bdk_query(root, Int(qx), Int(qy), x, y, active, left, right, minx, maxx, miny, maxy, best)
        if best == 8000001: return -1
        answers[batch] = best
    if pos != Int(length): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * batches): return -2
    for i in range(batches):
        let bits = UInt64(answers[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(8 * batches)
