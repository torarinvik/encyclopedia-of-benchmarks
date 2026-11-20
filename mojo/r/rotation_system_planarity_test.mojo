# Clean-room bounded rotation-system planarity recognizer.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rotation_system_planarity_test")
fn rotation_system_planarity_test(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 33: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 6 or mv < 0 or mv > 15 or length != c_size_t(2 + 2 * mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var adjacent = List[Int](capacity=36)
    var edge_u = List[Int](capacity=15)
    var edge_v = List[Int](capacity=15)
    for _ in range(36): adjacent.append(0)
    for _ in range(15):
        edge_u.append(0)
        edge_v.append(0)
    for e in range(m):
        let u64 = input[2 + 2 * e]
        let v64 = input[3 + 2 * e]
        if u64 < 0 or u64 >= v64 or v64 >= nv: return -1
        let u = Int(u64)
        let v = Int(v64)
        if adjacent[u * 6 + v] != 0: return -1
        adjacent[u * 6 + v] = 1
        adjacent[v * 6 + u] = 1
        edge_u[e] = u
        edge_v[e] = v
    if n >= 3 and m > 3 * n - 6: return 0

    var edge_id = List[Int](capacity=36)
    var neighbors = List[Int](capacity=36)
    var degree = List[Int](capacity=6)
    for _ in range(36):
        edge_id.append(-1)
        neighbors.append(0)
    for _ in range(6): degree.append(0)
    for u in range(n):
        for v in range(n): edge_id[u * 6 + v] = -1
    for e in range(m):
        let u = edge_u[e]
        let v = edge_v[e]
        edge_id[u * 6 + v] = e
        edge_id[v * 6 + u] = e
    for u in range(n):
        for v in range(n):
            if adjacent[u * 6 + v] != 0:
                neighbors[u * 6 + degree[u]] = v
                degree[u] += 1

    var component = List[Int](capacity=6)
    var component_size = List[Int](capacity=6)
    var component_vertices = List[Int](capacity=36)
    for _ in range(6):
        component.append(-1)
        component_size.append(0)
    for _ in range(36): component_vertices.append(0)
    var component_count = 0
    for root in range(n):
        if component[root] == -1:
            let cid = component_count
            component_count += 1
            var queue = List[Int](capacity=6)
            var head = 0
            var tail = 0
            component[root] = cid
            queue.append(root)
            tail += 1
            while head < tail:
                let here = queue[head]
                head += 1
                component_vertices[cid * 6 + component_size[cid]] = here
                component_size[cid] += 1
                for there in range(n):
                    if adjacent[here * 6 + there] != 0 and component[there] == -1:
                        component[there] = cid
                        queue.append(there)
                        tail += 1

    for cid in range(component_count):
        var component_edges = 0
        for e in range(m):
            if component[edge_u[e]] == cid: component_edges += 1
        if component_size[cid] >= 3 and component_edges > 3 * component_size[cid] - 6: return 0
        if component_size[cid] == 1: continue
        var rotation = List[Int](capacity=36)
        for _ in range(36): rotation.append(0)
        for i in range(component_size[cid]):
            let vertex = component_vertices[cid * 6 + i]
            for j in range(degree[vertex]): rotation[vertex * 6 + j] = neighbors[vertex * 6 + j]
        var found = False
        var done = False
        while not found and not done:
            var successor = List[Int](capacity=30)
            for _ in range(30): successor.append(-1)
            for i in range(component_size[cid]):
                let vertex = component_vertices[cid * 6 + i]
                let d = degree[vertex]
                for j in range(d):
                    let next = (j + 1) % d
                    let e = edge_id[vertex * 6 + rotation[vertex * 6 + j]]
                    let next_e = edge_id[vertex * 6 + rotation[vertex * 6 + next]]
                    let dart = 2 * e + (0 if edge_u[e] == vertex else 1)
                    let next_dart = 2 * next_e + (0 if edge_u[next_e] == vertex else 1)
                    successor[dart] = next_dart
            var used = List[Bool](capacity=30)
            for _ in range(30): used.append(False)
            var faces = 0
            for e in range(m):
                if component[edge_u[e]] == cid:
                    for orientation in range(2):
                        var dart = 2 * e + orientation
                        if not used[dart]:
                            faces += 1
                            while not used[dart]:
                                used[dart] = True
                                dart = successor[dart ^ 1]
            if component_size[cid] - component_edges + faces == 2:
                found = True
            else:
                var position = component_size[cid] - 1
                var advanced = False
                while position >= 0 and not advanced:
                    let vertex = component_vertices[cid * 6 + position]
                    let d = degree[vertex]
                    var pivot = d - 2
                    while pivot >= 1 and rotation[vertex * 6 + pivot] >= rotation[vertex * 6 + pivot + 1]: pivot -= 1
                    if pivot >= 1:
                        var swap_at = d - 1
                        while rotation[vertex * 6 + swap_at] <= rotation[vertex * 6 + pivot]: swap_at -= 1
                        let temp = rotation[vertex * 6 + pivot]
                        rotation[vertex * 6 + pivot] = rotation[vertex * 6 + swap_at]
                        rotation[vertex * 6 + swap_at] = temp
                        var left = pivot + 1
                        var right = d - 1
                        while left < right:
                            let value = rotation[vertex * 6 + left]
                            rotation[vertex * 6 + left] = rotation[vertex * 6 + right]
                            rotation[vertex * 6 + right] = value
                            left += 1
                            right -= 1
                        advanced = True
                    else:
                        for j in range(d): rotation[vertex * 6 + j] = neighbors[vertex * 6 + j]
                        position -= 1
                if not advanced: done = True
        if not found: return 0
    return 1
