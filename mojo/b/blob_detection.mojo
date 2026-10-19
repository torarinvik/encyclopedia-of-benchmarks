from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn blob_is_target(r: Int64, g: Int64, b: Int64, profile: Int64) -> Bool:
    let high = max(r, max(g, b)); let low = min(r, min(g, b)); let delta = high - low
    let hmin = 379 if profile == 0 else 398; let hmax = 496 if profile == 0 else 498; let smin = 436 if profile == 0 else 355
    if high == 0 or delta == 0 or 1000 * delta < smin * high: return False
    var hn: Int64 = 0
    if high == r:
        hn = (g - b) % (6 * delta)
        if hn < 0: hn += 6 * delta
    elif high == g: hn = 2 * delta + b - r
    else: hn = 4 * delta + r - g
    return hmin * 6 * delta <= 1000 * hn and 1000 * hn <= hmax * 6 * delta

@export("blob_detection")
fn blob_detection(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 49_155: return -1
    let hv = input[0]; let wv = input[1]; let profile = input[2]
    if hv < 1 or hv > 128 or wv < 1 or wv > 128 or (profile != 0 and profile != 1): return -1
    let h = Int(hv); let w = Int(wv); let cells = h * w
    if length != c_size_t(3 + 3 * cells): return -1
    for i in range(3 * cells):
        if input[3 + i] < 0 or input[3 + i] > 255: return -1
    var mask = List[Bool](capacity=cells); var eroded = List[Bool](capacity=cells); var opened = List[Bool](capacity=cells); var visited = List[Bool](capacity=cells)
    for _ in range(cells): mask.append(False); eroded.append(False); opened.append(False); visited.append(False)
    for i in range(cells): mask[i] = blob_is_target(input[3 + 3 * i], input[4 + 3 * i], input[5 + 3 * i], profile)
    for y in range(h):
        for x in range(w):
            var keep = True
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    if dx * dx + dy * dy > 9: continue
                    let yy = y + dy; let xx = x + dx
                    if yy >= 0 and yy < h and xx >= 0 and xx < w and not mask[yy * w + xx]: keep = False
            eroded[y * w + x] = keep
    for y in range(h):
        for x in range(w):
            var set = False
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    if dx * dx + dy * dy > 9: continue
                    let yy = y + dy; let xx = x + dx
                    if yy >= 0 and yy < h and xx >= 0 and xx < w and eroded[yy * w + xx]: set = True
            opened[y * w + x] = set
    var accepted: Int64 = 0
    for start in range(cells):
        if not opened[start] or visited[start]: continue
        var queue = List[Int](capacity=cells); queue.append(start); visited[start] = True; var head = 0; var area = 0
        while head < len(queue):
            let cell = queue[head]; head += 1; area += 1
            let y = cell // w; let x = cell % w
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if dx == 0 and dy == 0: continue
                    let yy = y + dy; let xx = x + dx
                    if yy < 0 or yy >= h or xx < 0 or xx >= w: continue
                    let neighbor = yy * w + xx
                    if opened[neighbor] and not visited[neighbor]: visited[neighbor] = True; queue.append(neighbor)
        if area >= 200 and area <= 5000:
            accepted += 1
            if accepted == 50: return accepted
    return accepted
