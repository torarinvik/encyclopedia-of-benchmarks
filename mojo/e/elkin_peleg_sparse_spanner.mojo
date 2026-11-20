from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

struct EpCluster:
    var center: Int
    var radius: Int
    var members: List[Bool]
    var tree: List[Bool]

fn ep_edge_id(index: List[Int], a: Int, b: Int) -> Int:
    let lo = min(a, b)
    let hi = max(a, b)
    return index[lo * 20 + hi]

fn ep_bfs(n: Int, adjacent: List[Bool], source: Int, allowed: List[Bool], restrict: Bool) -> (List[Int], List[Int]):
    var parent = List[Int](length=n, fill=-1)
    var distance = List[Int](length=n, fill=1000)
    var queue = List[Int](capacity=n)
    distance[source] = 0
    queue.append(source)
    var head = 0
    while head < len(queue):
        let u = queue[head]
        head += 1
        for v in range(n):
            if adjacent[u * 20 + v] and (not restrict or allowed[v]) and distance[v] == 1000:
                distance[v] = distance[u] + 1
                parent[v] = u
                queue.append(v)
    return (parent, distance)

fn ep_add_tree(n: Int, m: Int, adjacent: List[Bool], index: List[Int], allowed: List[Bool],
               root: Int, chosen: inout List[Bool]) -> Int:
    let (parent, distance) = ep_bfs(n, adjacent, root, allowed, True)
    var radius = 0
    for v in range(n):
        if allowed[v]:
            radius = max(radius, distance[v])
            if v != root:
                let edge = ep_edge_id(index, v, parent[v])
                if edge >= 0: chosen[edge] = True
    return radius

fn ep_set_distance(n: Int, distance: List[Int], left: List[Bool], right: List[Bool]) -> Int:
    var best = 1000
    for u in range(n):
        if left[u]:
            for v in range(n):
                if right[v]: best = min(best, distance[u * 20 + v])
    return best

fn ep_cluster_before(a: EpCluster, b: EpCluster, n: Int) -> Bool:
    if a.center != b.center: return a.center < b.center
    for v in range(n):
        if a.members[v] != b.members[v]: return a.members[v]
    return False

fn ep_connector(n: Int, m: Int, adjacent: List[Bool], index: List[Int],
                left: List[Bool], right: List[Bool], chosen: inout List[Bool]):
    var best_distance = 1000
    var best_path = List[Int](capacity=n)
    for source in range(n):
        if not left[source]: continue
        let (parent, distance) = ep_bfs(n, adjacent, source, List[Bool](), False)
        for target in range(n):
            if not right[target] or distance[target] == 1000 or distance[target] > best_distance: continue
            var reversed = List[Int](capacity=n)
            var v = target
            while v >= 0 and len(reversed) < n:
                reversed.append(v)
                if v == source: break
                v = parent[v]
            if len(reversed) == 0 or reversed[len(reversed) - 1] != source: continue
            var earlier = len(best_path) == 0 or distance[target] < best_distance
            if not earlier and distance[target] == best_distance:
                for i in range(len(reversed)):
                    let candidate = reversed[len(reversed) - 1 - i]
                    if candidate != best_path[i]:
                        earlier = candidate < best_path[i]
                        break
            if earlier:
                best_distance = distance[target]
                best_path = List[Int](capacity=n)
                for i in range(len(reversed)):
                    best_path.append(reversed[len(reversed) - 1 - i])
    for i in range(1, len(best_path)):
        let edge = ep_edge_id(index, best_path[i - 1], best_path[i])
        if edge >= 0: chosen[edge] = True

fn ep_sigma(n: Int) -> Int:
    var sigma = 1
    while sigma * sigma * sigma * sigma < n: sigma += 1
    return sigma

fn ep_supercluster(n: Int, m: Int, adjacent: List[Bool], index: List[Int], distance: List[Int],
                   input: List[EpCluster], threshold: Int, delta: Int,
                   chosen: inout List[Bool]) -> List[EpCluster]:
    var active = List[Bool](length=len(input), fill=True)
    var output = List[EpCluster](capacity=len(input))
    while True:
        var best = -1
        var neighborhoods = List[Bool](length=len(input) * len(input), fill=False)
        for i in range(len(input)):
            if not active[i]: continue
            var count = 0
            for j in range(len(input)):
                if active[j] and ep_set_distance(n, distance, input[i].members, input[j].members) <= delta:
                    neighborhoods[i * len(input) + j] = True
                    count += 1
            if count >= threshold and (best < 0 or ep_cluster_before(input[i], input[best], n)): best = i
        if best < 0: break
        var members = List[Bool](length=n, fill=False)
        var tree = List[Bool](length=m, fill=False)
        for j in range(len(input)):
            if not neighborhoods[best * len(input) + j]: continue
            active[j] = False
            for v in range(n): members[v] = members[v] or input[j].members[v]
            for e in range(m):
                tree[e] = tree[e] or input[j].tree[e]
                chosen[e] = chosen[e] or input[j].tree[e]
            if j != best:
                ep_connector(n, m, adjacent, index, input[best].members, input[j].members, chosen)
        output.append(EpCluster(center=input[best].center, radius=0, members=members, tree=tree))
    var remaining = List[Int](capacity=len(input))
    for i in range(len(input)):
        if active[i]: remaining.append(i)
    for i in range(1, len(remaining)):
        let key = remaining[i]
        var j = i
        while j > 0 and ep_cluster_before(input[key], input[remaining[j - 1]], n):
            remaining[j] = remaining[j - 1]
            j -= 1
        remaining[j] = key
    for i in range(len(remaining)):
        for j in range(i + 1, len(remaining)):
            if ep_set_distance(n, distance, input[remaining[i]].members, input[remaining[j]].members) <= delta:
                ep_connector(n, m, adjacent, index, input[remaining[i]].members,
                             input[remaining[j]].members, chosen)
    return output

fn ep_construct(n: Int, m: Int, adjacent: List[Bool], index: List[Int]) -> List[Bool]:
    var distance = List[Int](length=400, fill=1000)
    for source in range(n):
        let (_, row) = ep_bfs(n, adjacent, source, List[Bool](), False)
        for v in range(n): distance[source * 20 + v] = row[v]
    var chosen = List[Bool](length=m, fill=False)
    var uncovered = List[Bool](length=n, fill=True)
    var ground = List[EpCluster](capacity=n)
    while True:
        var root = -1
        for v in range(n):
            if uncovered[v]: root = v; break
        if root < 0: break
        var members = List[Bool](length=n, fill=False)
        members[root] = True
        var size = 1
        while True:
            var shell = List[Bool](length=n, fill=False)
            for v in range(n): shell[v] = members[v]
            var shell_size = 0
            for v in range(n):
                if not shell[v] and uncovered[v]:
                    for u in range(n):
                        if members[u] and adjacent[u * 20 + v]: shell[v] = True; break
                if shell[v]: shell_size += 1
            if shell_size == size or shell_size * shell_size * shell_size * shell_size < n * size * size * size * size: break
            for v in range(n):
                if shell[v] and not members[v]: members[v] = True; size += 1
        var shell = List[Bool](length=n, fill=False)
        for v in range(n): shell[v] = members[v]
        for v in range(n):
            if not shell[v] and uncovered[v]:
                for u in range(n):
                    if members[u] and adjacent[u * 20 + v]: shell[v] = True; break
        var tree = List[Bool](length=m, fill=False)
        radius = ep_add_tree(n, m, adjacent, index, members, root, tree)
        var shell_tree = List[Bool](length=m, fill=False)
        _ = ep_add_tree(n, m, adjacent, index, shell, root, shell_tree)
        for e in range(m): chosen[e] = chosen[e] or shell_tree[e]
        ground.append(EpCluster(center=root, radius=radius, members=members, tree=tree))
        for v in range(n):
            if members[v]: uncovered[v] = False
    var level = List[EpCluster](capacity=len(ground))
    for cluster in ground:
        if cluster.radius == 1: level.append(cluster)
    var final_clusters = ep_supercluster(n, m, adjacent, index, distance, level, ep_sigma(n), 16, chosen)
    for cluster in ground:
        if cluster.radius == 2 or cluster.radius == 3: final_clusters.append(cluster)
    for i in range(1, len(final_clusters)):
        let key = final_clusters[i]
        var j = i
        while j > 0 and ep_cluster_before(key, final_clusters[j - 1], n):
            final_clusters[j] = final_clusters[j - 1]
            j -= 1
        final_clusters[j] = key
    for i in range(len(final_clusters)):
        for j in range(i + 1, len(final_clusters)):
            if ep_set_distance(n, distance, final_clusters[i].members, final_clusters[j].members) <= 128:
                ep_connector(n, m, adjacent, index, final_clusters[i].members,
                             final_clusters[j].members, chosen)
    return chosen

@export("elkin_peleg_sparse_spanner")
fn elkin_peleg_sparse_spanner(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 383: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > 20 or m64 < 0 or m64 > 190 or length != c_size_t(2 + 2 * m64): return -1
    let n = Int(n64)
    let m = Int(m64)
    var adjacent = List[Bool](length=400, fill=False)
    var index = List[Int](length=400, fill=-1)
    for edge in range(m):
        let u64 = input[2 + 2 * edge]
        let v64 = input[3 + 2 * edge]
        if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
        let u = Int(u64)
        let v = Int(v64)
        if index[u * 20 + v] >= 0: return -1
        index[u * 20 + v] = edge
        index[v * 20 + u] = edge
        adjacent[u * 20 + v] = True
        adjacent[v * 20 + u] = True
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(m): return -2
    let chosen = ep_construct(n, m, adjacent, index)
    for edge in range(m): output[edge] = UInt8(1 if chosen[edge] else 0)
    return Int64(m)
