# Bounded list-stress profile; see the package's Apache-2.0 notice.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn els_compare(mut data: InlineArray[Int, 34], indices: InlineArray[Int, 34],
               a: Int, b: Int, complex: Bool, seed: Int) -> Int:
    if complex:
        if (data[a] & 128) == 0:
            data[a] = (data[a] & 65280) | 128 | ((data[a] ^ (data[a] >> 8) ^ seed) & 127)
        if (data[b] & 128) == 0:
            data[b] = (data[b] & 65280) | 128 | ((data[b] ^ (data[b] >> 8) ^ seed) & 127)
        return (data[a] & 127) - (data[b] & 127)
    data[a] = (data[a] & 65280) | ((data[a] >> 8) & 255)
    data[b] = (data[b] & 65280) | ((data[b] >> 8) & 255)
    return indices[a] - indices[b]

fn els_sort(mut data: InlineArray[Int, 34], indices: InlineArray[Int, 34],
            mut links: InlineArray[Int, 34], start: Int, complex: Bool, seed: Int) -> Int:
    var head = start
    var width = 1
    while True:
        var current = head
        var new_head = -1
        var tail = -1
        var merges = 0
        while current >= 0:
            merges += 1
            var right = current
            var left_count = 0
            for _ in range(width):
                left_count += 1
                right = links[right]
                if right < 0: break
            var right_count = width
            while left_count > 0 or (right_count > 0 and right >= 0):
                var chosen = 0
                if left_count == 0:
                    chosen = right; right = links[right]; right_count -= 1
                elif right_count == 0 or right < 0:
                    chosen = current; current = links[current]; left_count -= 1
                elif els_compare(data, indices, current, right, complex, seed) <= 0:
                    chosen = current; current = links[current]; left_count -= 1
                else:
                    chosen = right; right = links[right]; right_count -= 1
                if tail < 0: new_head = chosen
                else: links[tail] = chosen
                tail = chosen
            current = right
        links[tail] = -1
        head = new_head
        if merges <= 1: return head
        width *= 2
    return head

fn els_find(data: InlineArray[Int, 34], indices: InlineArray[Int, 34],
            links: InlineArray[Int, 34], head: Int, target: Int, byte: Int) -> Int:
    var node = head
    while node >= 0:
        if target >= 0:
            if indices[node] == target: return node
        elif (data[node] & 255) == byte: return node
        node = links[node]
    return -1

fn els_crc(value: Int, initial: Int) -> Int:
    var crc = initial
    for part in range(2):
        var byte = (value >> (8*part)) & 255
        for _ in range(8):
            let mix = (byte ^ crc) & 1
            byte >>= 1
            if mix != 0: crc ^= 16386
            crc >>= 1
            if mix != 0: crc |= 32768
    return crc

@export("embedded_list_stress")
fn embedded_list_stress(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    if input[0] < 4 or input[0] > 32 or input[1] < 1 or input[1] > 255: return -1
    if input[2] < 0 or input[2] > 32 or (input[3] != -1 and input[3] != 1): return -1
    let n = Int(input[0]); let seed = Int(input[1]); let searches = Int(input[2])
    var data = InlineArray[Int, 34](fill=0)
    var indices = InlineArray[Int, 34](fill=0)
    var links = InlineArray[Int, 34](fill=-1)
    data[0] = 32896; links[0] = 1
    data[n+1] = 65535; indices[n+1] = 32767
    for i in range(n):
        let byte = (((seed ^ i) & 15) << 3) | (i & 7)
        data[i+1] = (byte << 8) | byte
        links[i+1] = i+2
        let old_index = i+1
        if old_index < n//5: indices[i+1] = old_index
        else: indices[i+1] = (((old_index+1) & 7) << 8 | (old_index ^ seed)) & 16383
    var head = els_sort(data, indices, links, 0, False, seed)
    var target = Int(input[3]); var byte = 0
    var crc = 0; var found = 0; var missed = 0
    for k in range(searches):
        byte = k & 255
        let node = els_find(data, indices, links, head, target, byte)
        var previous = -1; var cursor = head
        while cursor >= 0:
            let next = links[cursor]
            links[cursor] = previous; previous = cursor; cursor = next
        head = previous
        if node < 0:
            missed += 1
            let first = links[head]
            if first >= 0: crc = (crc + ((data[first] >> 8) & 1)) & 65535
        else:
            found += 1
            if (data[node] & 1) != 0: crc = (crc + ((data[node] >> 9) & 1)) & 65535
            let next = links[node]
            if next >= 0:
                links[node] = links[next]
                links[next] = links[head]
                links[head] = next
        if target >= 0: target += 1
    crc = (crc + found*4 - missed) & 65535
    if input[3] > 0: head = els_sort(data, indices, links, head, True, seed)
    let anchor = links[head]
    if anchor >= 0:
        let removed = links[anchor]
        var temp = data[anchor]; data[anchor] = data[removed]; data[removed] = temp
        temp = indices[anchor]; indices[anchor] = indices[removed]; indices[removed] = temp
        links[anchor] = links[removed]; links[removed] = -1
        var finder = els_find(data, indices, links, head, target, byte)
        if finder < 0: finder = links[head]
        while finder >= 0:
            crc = els_crc(data[head], crc); finder = links[finder]
        temp = data[anchor]; data[anchor] = data[removed]; data[removed] = temp
        temp = indices[anchor]; indices[anchor] = indices[removed]; indices[removed] = temp
        links[removed] = links[anchor]; links[anchor] = removed
    head = els_sort(data, indices, links, head, False, seed)
    var finder = links[head]
    while finder >= 0:
        crc = els_crc(data[head], crc); finder = links[finder]
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 2: return -2
    output[0] = UInt8(crc & 255); output[1] = UInt8((crc >> 8) & 255)
    return 2
