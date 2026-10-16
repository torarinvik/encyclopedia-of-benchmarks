@[export: 'generic_heap']
pub fn generic_heap(a &i64, n usize) i64 {
    if isnil(a) || n < 1 || n > 769 { return -1 }
    unsafe {
        if a[0] < 0 || a[0] > 256 || n != usize(1 + 3 * a[0]) { return -1 }
        mut ids := []i64{len: 128, init: 0}
        mut ps := []i64{len: 128, init: 0}
        mut pos := []int{len: 4096, init: -1}
        mut z := 0
        mut h := u64(0xcbf29ce484222325)
        for k in 0 .. int(a[0]) {
            op := a[1 + 3*k]
            id := a[2 + 3*k]
            v := a[3 + 3*k]
            if op == 0 {
                if id < 0 || id >= 4096 || v < -2147483648 || v > 2147483647 || pos[int(id)] >= 0 || z >= 128 { return -1 }
                ids[z] = id
                ps[z] = v
                pos[int(id)] = z
                mut i := z
                z += 1
                for i > 0 {
                    q := (i - 1) / 2
                    if ps[i] <= ps[q] { break }
                    ti := ids[i]; ids[i] = ids[q]; ids[q] = ti
                    tv := ps[i]; ps[i] = ps[q]; ps[q] = tv
                    pos[int(ids[i])] = i; pos[int(ids[q])] = q
                    i = q
                }
            } else if op == 1 || op == 2 {
                if id != 0 || v != 0 || z == 0 { return -1 }
                ri := ids[0]; rv := ps[0]
                if op == 2 {
                    ti := ids[0]; ids[0] = ids[z-1]; ids[z-1] = ti
                    tv := ps[0]; ps[0] = ps[z-1]; ps[z-1] = tv
                    pos[int(ids[0])] = 0; pos[int(ids[z-1])] = z-1
                    z -= 1
                    pos[int(ri)] = -1
                    if z > 0 {
                        mut i := 0
                        for 2*i+1 < z {
                            mut q := 2*i+1
                            if q+1 < z && ps[q+1] > ps[q] { q += 1 }
                            if ps[i] >= ps[q] { break }
                            ti = ids[i]; ids[i] = ids[q]; ids[q] = ti
                            tv = ps[i]; ps[i] = ps[q]; ps[q] = tv
                            pos[int(ids[i])] = i; pos[int(ids[q])] = q
                            i = q
                        }
                    }
                }
                h = hashv(hashv(h, ri), rv)
            } else if op == 3 {
                if id < 0 || id >= 4096 || v < -2147483648 || v > 2147483647 || pos[int(id)] < 0 { return -1 }
                mut i := pos[int(id)]
                ps[i] = v
                for i > 0 {
                    q := (i - 1) / 2
                    if ps[i] <= ps[q] { break }
                    ti := ids[i]; ids[i] = ids[q]; ids[q] = ti
                    tv := ps[i]; ps[i] = ps[q]; ps[q] = tv
                    pos[int(ids[i])] = i; pos[int(ids[q])] = q
                    i = q
                }
            } else if op == 4 || op == 5 {
                if id != 0 || v != 0 { return -1 }
                obs := i64(z)
                if op == 5 { if z == 0 { obs = 1 } else { obs = 0 } }
                h = hashv(h, obs)
            } else { return -1 }
        }
        return i64(h)
    }
}

fn hashv(h0 u64, v i64) u64 {
    mut h := h0
    bits := u64(v)
    for i in 0 .. 8 { h = (h ^ ((bits >> (8*i)) & 255)) * u64(0x100000001b3) }
    return h
}
