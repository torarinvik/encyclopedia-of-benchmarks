from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn wiki_reverse(values: UnsafePointer[Int64, MutAnyOrigin], first: Int, last: Int):
    var lo = first
    var hi = last
    while lo < hi:
        hi -= 1
        if lo >= hi: break
        let temp = values[lo]
        values[lo] = values[hi]
        values[hi] = temp
        lo += 1

fn wiki_rotate(values: UnsafePointer[Int64, MutAnyOrigin], scratch: UnsafePointer[Int64, MutAnyOrigin],
               first: Int, middle: Int, last: Int, cache: Int):
    let left = middle - first
    let right = last - middle
    if left == 0 or right == 0: return
    if left <= right and left <= cache:
        for i in range(left): scratch[i] = values[first + i]
        for i in range(right): values[first + i] = values[middle + i]
        for i in range(left): values[first + right + i] = scratch[i]
    elif right < left and right <= cache:
        for i in range(right): scratch[i] = values[middle + i]
        var i = left
        while i > 0:
            i -= 1
            values[first + right + i] = values[first + i]
        for i in range(right): values[first + i] = scratch[i]
    else:
        wiki_reverse(values, first, middle)
        wiki_reverse(values, middle, last)
        wiki_reverse(values, first, last)

fn wiki_insertion(values: UnsafePointer[Int64, MutAnyOrigin], first: Int, last: Int):
    for i in range(first + 1, last):
        let item = values[i]
        var j = i
        while j > first and item < values[j - 1]:
            values[j] = values[j - 1]
            j -= 1
        values[j] = item

fn wiki_merge(values: UnsafePointer[Int64, MutAnyOrigin], scratch: UnsafePointer[Int64, MutAnyOrigin],
              first: Int, middle: Int, last: Int):
    let count = middle - first
    for i in range(count): scratch[i] = values[first + i]
    var left = 0
    var right = middle
    var dest = first
    while left < count and right < last:
        if scratch[left] <= values[right]:
            values[dest] = scratch[left]
            left += 1
        else:
            values[dest] = values[right]
            right += 1
        dest += 1
    while left < count:
        values[dest] = scratch[left]
        left += 1
        dest += 1

fn wiki_block_merge(values: UnsafePointer[Int64, MutAnyOrigin], scratch: UnsafePointer[Int64, MutAnyOrigin],
                    first: Int, middle: Int, last: Int, cache: Int):
    let total = last - first
    var block = 1
    while block + 1 <= total // (block + 1): block += 1
    var left = first
    var mid = middle
    while left < mid and mid < last:
        if values[left] <= values[mid]:
            let boundary = values[mid]
            var lo = left
            var hi = mid
            while lo < hi:
                let probe = lo + (hi - lo) // 2
                if values[probe] <= boundary: lo = probe + 1
                else: hi = probe
            left = lo
        else:
            let key = values[left]
            var lo = mid
            var hi = last
            while lo < hi:
                let probe = lo + (hi - lo) // 2
                if values[probe] < key: lo = probe + 1
                else: hi = probe
            let end = min(lo, mid + block)
            let moved = end - mid
            if moved == 0: left += 1
            else:
                wiki_rotate(values, scratch, left, mid, end, cache)
                left += moved
                mid += moved

@export("wikisort")
fn wikisort(values: UnsafePointer[Int64, MutAnyOrigin], scratch: UnsafePointer[Int64, MutAnyOrigin],
            length: c_size_t) abi("C"):
    if length < 2 or length > 2048: return
    let n = Int(length)
    let cache = min(n, 512)
    if n <= 32:
        wiki_insertion(values, 0, n)
        return
    var start = 0
    while start < n:
        wiki_insertion(values, start, min(start + 16, n))
        start += 16
    var width = 16
    while width < n:
        var first = 0
        while first < n:
            let middle = min(first + width, n)
            let last = min(middle + width, n)
            if middle < last and values[middle] < values[middle - 1]:
                if values[last - 1] < values[first]: wiki_rotate(values, scratch, first, middle, last, cache)
                elif middle - first <= cache: wiki_merge(values, scratch, first, middle, last)
                else: wiki_block_merge(values, scratch, first, middle, last, cache)
            first = last
        if width > n // 2: break
        width *= 2
