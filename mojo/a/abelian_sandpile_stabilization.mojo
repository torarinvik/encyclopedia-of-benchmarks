from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LENGTH = 19
const MAX_TOPPLES = 1488

fn abelian_sandpile_stabilization_impl(input: view[Int64]) -> Int64:
    if input.length < 2 or input.length > MAX_LENGTH:
        return -1
    if input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 4:
        return -1
    let rows = Int(input[0])
    let cols = Int(input[1])
    let cells = rows * cols
    if input.length != 2 + cells:
        return -1

    var board = InlineArray[Int64, 16](fill=0)
    for site in range(cells):
        let height = input[2 + site]
        if height < 0 or height > 31:
            return -1
        board[site] = height

    var queue = InlineArray[Int, 16](fill=0)
    var queued = InlineArray[Bool, 16](fill=False)
    var head = 0
    var tail = 0
    var queue_count = 0
    for site in range(cells):
        if board[site] >= 4:
            queue[tail] = site
            tail = (tail + 1) % cells
            queue_count += 1
            queued[site] = True

    var topples = 0
    while queue_count > 0:
        let site = queue[head]
        head = (head + 1) % cells
        queue_count -= 1
        queued[site] = False
        if board[site] < 4:
            continue
        let row = site // cols
        let col = site % cols
        board[site] -= 4
        topples += 1
        if topples > MAX_TOPPLES:
            return -1

        if row > 0:
            let next = site - cols
            board[next] += 1
            if board[next] >= 4 and not queued[next]:
                queue[tail] = next
                tail = (tail + 1) % cells
                queue_count += 1
                queued[next] = True
        if col + 1 < cols:
            let next = site + 1
            board[next] += 1
            if board[next] >= 4 and not queued[next]:
                queue[tail] = next
                tail = (tail + 1) % cells
                queue_count += 1
                queued[next] = True
        if row + 1 < rows:
            let next = site + cols
            board[next] += 1
            if board[next] >= 4 and not queued[next]:
                queue[tail] = next
                tail = (tail + 1) % cells
                queue_count += 1
                queued[next] = True
        if col > 0:
            let next = site - 1
            board[next] += 1
            if board[next] >= 4 and not queued[next]:
                queue[tail] = next
                tail = (tail + 1) % cells
                queue_count += 1
                queued[next] = True
        if board[site] >= 4 and not queued[site]:
            queue[tail] = site
            tail = (tail + 1) % cells
            queue_count += 1
            queued[site] = True

    var result: Int64 = 0
    var place: Int64 = 1
    for site in range(cells):
        result += board[site] * place
        place *= 4
    return result

@export("abelian_sandpile_stabilization")
fn abelian_sandpile_stabilization(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_LENGTH:
        return -1
    let input_view: view[Int64] = input[0:Int(length)]
    abelian_sandpile_stabilization_impl(input_view)
