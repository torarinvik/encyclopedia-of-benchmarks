from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_CELLS = 64
alias MAX_INPUT = 66

@export("trapping_rain_water_ii")
fn trapping_rain_water_ii(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8:
        return -1
    let rows = Int(input[0])
    let cols = Int(input[1])
    if length != c_size_t(2 + rows * cols):
        return -1

    var heights = InlineArray[Int64, MAX_CELLS]()
    for cell in range(rows * cols):
        let height = input[2 + cell]
        if height < 0 or height > 1000:
            return -1
        heights[cell] = height
    var visited = InlineArray[Bool, MAX_CELLS]()
    var heap = InlineArray[Int64, MAX_CELLS]()
    var heap_size = 0
    for row in range(rows):
        for col in range(cols):
            if row == 0 or row + 1 == rows or col == 0 or col + 1 == cols:
                let cell = row * cols + col
                if not visited[cell]:
                    visited[cell] = True
                    let key = heights[cell] * 64 + Int64(cell)
                    var position = heap_size
                    heap_size += 1
                    while position > 0:
                        let parent = (position - 1) // 2
                        if heap[parent] <= key:
                            break
                        heap[position] = heap[parent]
                        position = parent
                    heap[position] = key

    var retained: Int64 = 0
    while heap_size > 0:
        let key = heap[0]
        heap_size -= 1
        if heap_size > 0:
            let last = heap[heap_size]
            var position = 0
            while 2 * position + 1 < heap_size:
                var child = 2 * position + 1
                if child + 1 < heap_size and heap[child + 1] < heap[child]:
                    child += 1
                if heap[child] >= last:
                    break
                heap[position] = heap[child]
                position = child
            heap[position] = last

        let level = key // 64
        let cell = Int(key % 64)
        let row = cell // cols
        let col = cell % cols
        for direction in range(4):
            var nr = row
            var nc = col
            if direction == 0:
                nr -= 1
            elif direction == 1:
                nr += 1
            elif direction == 2:
                nc -= 1
            else:
                nc += 1
            if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
                continue
            let neighbor = nr * cols + nc
            if visited[neighbor]:
                continue
            visited[neighbor] = True
            let height = heights[neighbor]
            if height < level:
                retained += level - height
            let next_level = max(level, height)
            let next_key = next_level * 64 + Int64(neighbor)
            var position = heap_size
            heap_size += 1
            while position > 0:
                let parent = (position - 1) // 2
                if heap[parent] <= next_key:
                    break
                heap[position] = heap[parent]
                position = parent
            heap[position] = next_key
    return retained
