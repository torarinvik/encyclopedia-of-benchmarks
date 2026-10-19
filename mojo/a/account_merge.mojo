from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn compare_text(values: UnsafePointer[Int64, ImmutAnyOrigin], a_start: Int64, a_len: Int64,
                b_start: Int64, b_len: Int64) -> Int32:
    var i: Int64 = 0
    while i < a_len and i < b_len:
        let a = values[a_start + i]
        let b = values[b_start + i]
        if a < b:
            return -1
        if a > b:
            return 1
        i += 1
    if a_len < b_len:
        return -1
    if a_len > b_len:
        return 1
    return 0

fn write_u16(output: UnsafePointer[UInt8, MutAnyOrigin], position: Int, value: Int):
    output[position] = UInt8(value & 255)
    output[position + 1] = UInt8((value >> 8) & 255)

@export("account_merge")
fn account_merge(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 100000:
        return -1
    if values[0] < 0 or values[0] > 64:
        return -1
    let account_count = Int(values[0])
    var name_start = List[Int64](length=account_count, fill=0)
    var name_len = List[Int64](length=account_count, fill=0)
    var parent = List[Int64](length=account_count, fill=0)
    var rank = List[Int64](length=account_count, fill=0)
    var email_start = List[Int64](length=1024, fill=0)
    var email_len = List[Int64](length=1024, fill=0)
    var email_account = List[Int64](length=1024, fill=0)
    var email_root = List[Int64](length=1024, fill=0)
    var table = List[Int64](length=2048, fill=-1)
    for i in range(account_count):
        parent[i] = i
    var pos: Int = 1
    var refs: Int = 0
    for account in range(account_count):
        if pos >= Int(length) or values[pos] < 1 or values[pos] > 64:
            return -1
        let nl = values[pos]
        pos += 1
        if nl > Int64(Int(length) - pos):
            return -1
        name_start[account] = Int64(pos)
        name_len[account] = nl
        for j in range(nl):
            if values[pos + Int(j)] < 32 or values[pos + Int(j)] > 126:
                return -1
        pos += Int(nl)
        if pos >= Int(length) or values[pos] < 0 or values[pos] > 1024:
            return -1
        let ec = Int(values[pos])
        pos += 1
        if ec > 1024 - refs:
            return -1
        for _ in range(ec):
            if pos >= Int(length) or values[pos] < 1 or values[pos] > 64:
                return -1
            let el = values[pos]
            pos += 1
            if el > Int64(Int(length) - pos):
                return -1
            for j in range(el):
                if values[pos + Int(j)] < 33 or values[pos + Int(j)] > 126:
                    return -1
            email_start[refs] = Int64(pos)
            email_len[refs] = el
            email_account[refs] = Int64(account)
            var hash: UInt64 = 14695981039346656037
            for j in range(el):
                hash = (hash ^ UInt64(values[pos + Int(j)])) * 1099511628211
            var slot = Int(hash & 2047)
            while table[slot] >= 0:
                let prior = Int(table[slot])
                if compare_text(values, Int64(pos), el, email_start[prior], email_len[prior]) == 0:
                    var ra = Int64(account)
                    while parent[Int(ra)] != ra:
                        parent[Int(ra)] = parent[Int(parent[Int(ra)])]
                        ra = parent[Int(ra)]
                    var rb = email_account[prior]
                    while parent[Int(rb)] != rb:
                        parent[Int(rb)] = parent[Int(parent[Int(rb)])]
                        rb = parent[Int(rb)]
                    if ra != rb:
                        if rank[Int(ra)] < rank[Int(rb)]:
                            parent[Int(ra)] = rb
                        elif rank[Int(ra)] > rank[Int(rb)]:
                            parent[Int(rb)] = ra
                        else:
                            parent[Int(rb)] = ra
                            rank[Int(ra)] += 1
                    break
                slot = (slot + 1) & 2047
            if table[slot] < 0:
                table[slot] = Int64(refs)
            refs += 1
            pos += Int(el)
    if pos != Int(length):
        return -1

    var roots = List[Int64](length=account_count, fill=-1)
    var root_seen = List[Bool](length=account_count, fill=False)
    var group_count = 0
    for account in range(account_count):
        var root = Int64(account)
        while parent[Int(root)] != root:
            parent[Int(root)] = parent[Int(parent[Int(root)])]
            root = parent[Int(root)]
        roots[account] = root
        if compare_text(values, name_start[account], name_len[account], name_start[Int(root)], name_len[Int(root)]) != 0:
            return -1
        if not root_seen[Int(root)]:
            root_seen[Int(root)] = True
            roots[group_count] = root
            group_count += 1

    var group_email_count = List[Int64](length=account_count, fill=0)
    var first_email = List[Int64](length=account_count, fill=-1)
    var unique = List[Int64](capacity=refs)
    for slot in range(2048):
        if table[slot] >= 0:
            let index = Int(table[slot])
            var root = email_account[index]
            while parent[Int(root)] != root:
                parent[Int(root)] = parent[Int(parent[Int(root)])]
                root = parent[Int(root)]
            email_root[index] = root
            group_email_count[Int(root)] += 1
            unique.append(Int64(index))
    # Stable insertion sort by email text.
    for i in range(1, len(unique)):
        let item = unique[i]
        var j = i
        while j > 0:
            let prev = Int(unique[j - 1])
            let curr = Int(item)
            if compare_text(values, email_start[curr], email_len[curr], email_start[prev], email_len[prev]) >= 0:
                break
            unique[j] = unique[j - 1]
            j -= 1
        unique[j] = item
    for i in range(len(unique)):
        let ei = Int(unique[i])
        let root = Int(email_root[ei])
        if first_email[root] < 0:
            first_email[root] = Int64(ei)
    # Sort groups by owner, then email-free first, then first email.
    for i in range(1, group_count):
        let item = roots[i]
        var j = i
        while j > 0:
            let prev = roots[j - 1]
            var cmp = compare_text(values, name_start[Int(item)], name_len[Int(item)], name_start[Int(prev)], name_len[Int(prev)])
            if cmp == 0:
                if group_email_count[Int(item)] == 0 and group_email_count[Int(prev)] != 0:
                    cmp = -1
                elif group_email_count[Int(item)] != 0 and group_email_count[Int(prev)] == 0:
                    cmp = 1
                elif group_email_count[Int(item)] == 0:
                    if item < prev:
                        cmp = -1
                    elif item > prev:
                        cmp = 1
                else:
                    let a = Int(first_email[Int(item)])
                    let b = Int(first_email[Int(prev)])
                    cmp = compare_text(values, email_start[a], email_len[a], email_start[b], email_len[b])
                    if cmp == 0:
                        if item < prev:
                            cmp = -1
                        elif item > prev:
                            cmp = 1
            if cmp >= 0:
                break
            roots[j] = roots[j - 1]
            j -= 1
        roots[j] = item

    var required = 2
    for g in range(group_count):
        let root = Int(roots[g])
        required += 4 + Int(name_len[root])
        for i in range(len(unique)):
            let ei = Int(unique[i])
            if email_root[ei] == Int64(root):
                required += 2 + Int(email_len[ei])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var outpos = 0
    write_u16(output, outpos, group_count)
    outpos += 2
    for g in range(group_count):
        let root = Int(roots[g])
        write_u16(output, outpos, Int(name_len[root]))
        outpos += 2
        write_u16(output, outpos, Int(group_email_count[root]))
        outpos += 2
        for j in range(name_len[root]):
            output[outpos] = UInt8(values[name_start[root] + j])
            outpos += 1
        for i in range(len(unique)):
            let ei = Int(unique[i])
            if email_root[ei] != Int64(root):
                continue
            write_u16(output, outpos, Int(email_len[ei]))
            outpos += 2
            for j in range(email_len[ei]):
                output[outpos] = UInt8(values[email_start[ei] + j])
                outpos += 1
    return Int64(outpos)
