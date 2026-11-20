# Clean-room bounded Kosaraju plus condensation quotient construction.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("scc_condensation_dag")
fn scc_condensation_dag(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 58: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 0 or nv > 8 or mv < 0 or mv > 28: return -1
    let n = Int(nv)
    let m = Int(mv)
    if length != c_size_t(2 + 2 * m): return -1

    var adjacency = List[UInt16](capacity=8)
    var reverse = List[UInt16](capacity=8)
    var visited = List[Bool](capacity=8)
    var order = List[Int](capacity=8)
    var stack_vertex = List[Int](capacity=8)
    var stack_next = List[Int](capacity=8)
    var raw_component = List[Int](capacity=8)
    var minimum = List[Int](capacity=8)
    var raw_order = List[Int](capacity=8)
    var canonical = List[Int](capacity=8)
    var labels = List[Int](capacity=8)
    var row_mask = List[UInt8](capacity=8)
    for _ in range(8):
        adjacency.append(UInt16(0))
        reverse.append(UInt16(0))
        visited.append(False)
        order.append(0)
        stack_vertex.append(0)
        stack_next.append(0)
        raw_component.append(-1)
        minimum.append(8)
        raw_order.append(0)
        canonical.append(0)
        labels.append(0)
        row_mask.append(UInt8(0))

    for edge in range(m):
        let source = input[2 + 2 * edge]
        let target = input[3 + 2 * edge]
        if source < 0 or source >= nv or target < 0 or target >= nv: return -1
        adjacency[Int(source)] = adjacency[Int(source)] | (UInt16(1) << Int(target))
        reverse[Int(target)] = reverse[Int(target)] | (UInt16(1) << Int(source))

    var order_count = 0
    for start in range(n):
        if visited[start]: continue
        var stack_size = 1
        stack_vertex[0] = start
        stack_next[0] = 0
        visited[start] = True
        while stack_size > 0:
            let frame = stack_size - 1
            let vertex = stack_vertex[frame]
            var candidate = stack_next[frame]
            while candidate < n and (adjacency[vertex] & (UInt16(1) << candidate)) == 0:
                candidate += 1
            if candidate < n:
                stack_next[frame] = candidate + 1
                if not visited[candidate]:
                    visited[candidate] = True
                    stack_vertex[stack_size] = candidate
                    stack_next[stack_size] = 0
                    stack_size += 1
            else:
                order[order_count] = vertex
                order_count += 1
                stack_size -= 1

    for vertex in range(n):
        raw_component[vertex] = -1
        visited[vertex] = False
    var component_count = 0
    while order_count > 0:
        order_count -= 1
        let start = order[order_count]
        if visited[start]: continue
        var stack_size = 1
        stack_vertex[0] = start
        visited[start] = True
        raw_component[start] = component_count
        while stack_size > 0:
            stack_size -= 1
            let vertex = stack_vertex[stack_size]
            for next in range(n):
                if (reverse[vertex] & (UInt16(1) << next)) != 0 and not visited[next]:
                    visited[next] = True
                    raw_component[next] = component_count
                    stack_vertex[stack_size] = next
                    stack_size += 1
        component_count += 1

    for component in range(component_count):
        minimum[component] = n
        raw_order[component] = component
    for vertex in range(n):
        let component = raw_component[vertex]
        if vertex < minimum[component]: minimum[component] = vertex
    for i in range(1, component_count):
        let key = raw_order[i]
        var j = i
        while j > 0 and minimum[raw_order[j - 1]] > minimum[key]:
            raw_order[j] = raw_order[j - 1]
            j -= 1
        raw_order[j] = key
    for i in range(component_count): canonical[raw_order[i]] = i
    for vertex in range(n): labels[vertex] = canonical[raw_component[vertex]]
    for source in range(n):
        for target in range(n):
            if (adjacency[source] & (UInt16(1) << target)) == 0: continue
            let left = labels[source]
            let right = labels[target]
            if left != right: row_mask[left] = row_mask[left] | UInt8(1 << right)

    let output_size = 1 + n + component_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_size): return -2
    var staged = List[UInt8](capacity=output_size)
    for _ in range(output_size): staged.append(0)
    staged[0] = UInt8(component_count)
    for vertex in range(n): staged[1 + vertex] = UInt8(labels[vertex])
    for component in range(component_count): staged[1 + n + component] = row_mask[component]
    for index in range(output_size): output[index] = staged[index]
    return Int64(output_size)
