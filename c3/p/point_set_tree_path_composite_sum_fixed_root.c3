module point_set_tree_path_composite_sum_fixed_root;

const usz N = 16, Q = 32, BASE = 16, INPUT_MAX = 5 * N + 4 * Q - 2;
const long MOD = 998244353;

fn usz pts_find(usz[N]* parent, usz x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}
fn long pts_norm(long x) { x %= MOD; if (x < 0) x += MOD; return x; }
fn void pts_compose(long lm, long la, long rm, long ra, long* out) {
    out[0] = lm * rm % MOD;
    out[1] = (lm * ra + la) % MOD;
}
fn void pts_set(usz u, usz[N]* pos, long[N]* lm, long[N]* la,
                long[2 * BASE]* sm, long[2 * BASE]* sa) {
    usz k = BASE + pos[u]; sm[k] = lm[u]; sa[k] = la[u];
    while (k > 1) {
        k /= 2;
        pts_compose(sm[2*k], sa[2*k], sm[2*k+1], sa[2*k+1], &sm[k]);
    }
}
fn long pts_chain(usz h, usz[N]* pos, usz[N]* ends,
                  long[2 * BASE]* sm, long[2 * BASE]* sa) {
    usz l = BASE + pos[h], r = BASE + ends[h];
    long lm = 1, la = 0, rm = 1, ra = 0, tmp[2];
    while (l < r) {
        if ((l & 1) != 0) { pts_compose(lm, la, sm[l], sa[l], &tmp[0]); lm = tmp[0]; la = tmp[1]; l += 1; }
        if ((r & 1) != 0) { r -= 1; pts_compose(sm[r], sa[r], rm, ra, &tmp[0]); rm = tmp[0]; ra = tmp[1]; }
        l /= 2; r /= 2;
    }
    pts_compose(lm, la, rm, ra, &tmp[0]);
    return tmp[1];
}
fn void pts_store(uint8* out, usz at, long x) {
    ulong bits = (ulong)x;
    for (usz i = 0; i < 8; i += 1) out[at+i] = (uint8)((bits >> (8*i)) & 255);
}

fn long point_set_tree_path_composite_sum_fixed_root(long* input, usz length,
    uint8* output, usz capacity) @export("point_set_tree_path_composite_sum_fixed_root") {
    if (input == null || length < 2 || length > INPUT_MAX) return -1;
    long nr = input[0], qr = input[1];
    if (nr < 1 || nr > (long)N || qr < 1 || qr > (long)Q) return -1;
    usz n = (usz)nr, q = (usz)qr, cur = 2;
    long[N] value = zeroed;
    for (usz u = 0; u < n; u += 1) {
        if (cur >= length) return -1;
        value[u] = input[cur++];
        if (value[u] < 0 || value[u] >= MOD) return -1;
    }
    int[N * N] edge_at = zeroed;
    for (usz i = 0; i < N*N; i += 1) edge_at[i] = -1;
    long[N-1] eu = zeroed, ev = zeroed, eb = zeroed, ec = zeroed;
    usz[N] dsu = zeroed, dsz = zeroed;
    for (usz u = 0; u < n; u += 1) { dsu[u] = u; dsz[u] = 1; }
    for (usz e = 0; e + 1 < n; e += 1) {
        if (cur + 4 > length) return -1;
        long ur = input[cur++], vr = input[cur++], b = input[cur++], c = input[cur++];
        if (ur < 0 || ur >= nr || vr < 0 || vr >= nr || ur == vr || b < 1 || b >= MOD || c < 0 || c >= MOD) return -1;
        usz u = (usz)ur, v = (usz)vr, ru = pts_find(dsu, u), rv = pts_find(dsu, v);
        if (ru == rv) return -1;
        if (dsz[ru] < dsz[rv]) { usz t = ru; ru = rv; rv = t; }
        dsu[rv] = ru; dsz[ru] += dsz[rv]; eu[e] = ur; ev[e] = vr; eb[e] = b; ec[e] = c;
        edge_at[u*N+v] = (int)e; edge_at[v*N+u] = (int)e;
    }
    long[Q] kind = zeroed, ox = zeroed, oy = zeroed, oz = zeroed;
    for (usz i = 0; i < q; i += 1) {
        if (cur >= length) return -1;
        kind[i] = input[cur++];
        if (kind[i] == 0) {
            if (cur + 2 > length) return -1;
            ox[i] = input[cur++]; oy[i] = input[cur++];
            if (ox[i] < 0 || ox[i] >= nr || oy[i] < 0 || oy[i] >= MOD) return -1;
        } else if (kind[i] == 1) {
            if (cur + 3 > length) return -1;
            ox[i] = input[cur++]; oy[i] = input[cur++]; oz[i] = input[cur++];
            if (ox[i] < 0 || ox[i] >= nr-1 || oy[i] < 1 || oy[i] >= MOD || oz[i] < 0 || oz[i] >= MOD) return -1;
        } else return -1;
    }
    if (cur != length) return -1;
    usz bytes = 8*q;
    if (output == null || capacity < bytes) return -2;

    long[N] parent = zeroed, pedge = zeroed, down = zeroed, value_sum = zeroed;
    usz[N] order = zeroed, stack = zeroed, sub = zeroed;
    for (usz u = 0; u < n; u += 1) { parent[u] = -2; pedge[u] = -1; sub[u] = 1; }
    parent[0] = -1; usz count = 0, top = 1; stack[0] = 0;
    while (top > 0) {
        top -= 1; usz u = stack[top]; order[count++] = u;
        for (usz v = 0; v < n; v += 1) if (edge_at[u*N+v] >= 0 && (long)v != parent[u]) {
            parent[v] = (long)u; pedge[v] = edge_at[u*N+v]; stack[top++] = v;
        }
    }
    long[N] heavy = zeroed;
    for (usz u = 0; u < n; u += 1) heavy[u] = -1;
    for (usz i = count; i > 0; i -= 1) {
        usz u = order[i-1], best = 0;
        for (usz v = 0; v < n; v += 1) if (parent[v] == (long)u) {
            sub[u] += sub[v];
            if (sub[v] > best || (sub[v] == best && (heavy[u] < 0 || v < (usz)heavy[u]))) { best = sub[v]; heavy[u] = (long)v; }
        }
    }
    usz[N] head = zeroed, pos = zeroed, ends = zeroed, hs = zeroed;
    usz timer = 0; top = 1; hs[0] = 0;
    while (top > 0) {
        usz h = hs[--top], u = h;
        while (true) {
            head[u] = h; pos[u] = timer++;
            for (usz v = 0; v < n; v += 1) if (parent[v] == (long)u && (long)v != heavy[u]) hs[top++] = v;
            if (heavy[u] < 0) break;
            u = (usz)heavy[u];
        }
        ends[h] = timer;
    }
    for (usz i = count; i > 0; i -= 1) {
        usz u = order[i-1]; down[u] = value[u];
        for (usz v = 0; v < n; v += 1) if (parent[v] == (long)u) {
            usz e = (usz)pedge[v]; down[u] += eb[e]*down[v] + ec[e]*(long)sub[v];
        }
        down[u] = pts_norm(down[u]);
    }
    long[N] lm = zeroed, la = zeroed;
    for (usz u = 0; u < n; u += 1) {
        la[u] = value[u];
        for (usz v = 0; v < n; v += 1) if (parent[v] == (long)u) {
            usz e = (usz)pedge[v];
            if ((long)v == heavy[u]) { lm[u] = eb[e]; la[u] += ec[e]*(long)sub[v]; }
            else la[u] += eb[e]*down[v] + ec[e]*(long)sub[v];
        }
        la[u] = pts_norm(la[u]);
    }
    long[2*BASE] sm = zeroed, sa = zeroed, tmp[2];
    for (usz i = 0; i < 2*BASE; i += 1) sm[i] = 1;
    for (usz u = 0; u < n; u += 1) { sm[BASE+pos[u]]=lm[u]; sa[BASE+pos[u]]=la[u]; }
    for (usz i = BASE-1; i > 0; i -= 1) { pts_compose(sm[2*i],sa[2*i],sm[2*i+1],sa[2*i+1],&tmp[0]);sm[i]=tmp[0];sa[i]=tmp[1]; }
    long[N] current = zeroed;
    for (usz u = 0; u < n; u += 1) if (head[u] == u) current[u] = down[u];
    for (usz qi = 0; qi < q; qi += 1) {
        usz start;
        if (kind[qi] == 0) {
            usz u = (usz)ox[qi]; la[u] = pts_norm(la[u] + oy[qi] - value[u]); value[u] = oy[qi];
            pts_set(u,pos,lm,la,sm,sa); start = u;
        } else {
            usz e=(usz)ox[qi],u=(usz)eu[e],v=(usz)ev[e],child=parent[u]==(long)v?u:v,p=(usz)parent[child];
            long ob=eb[e],oc=ec[e],nb=oy[qi],nc=oz[qi];
            if (heavy[p] == (long)child) { lm[p]=nb; la[p]=pts_norm(la[p]+(nc-oc)*(long)sub[child]); }
            else la[p]=pts_norm(la[p]+(nb-ob)*current[child]+(nc-oc)*(long)sub[child]);
            eb[e]=nb;ec[e]=nc;pts_set(p,pos,lm,la,sm,sa);start=p;
        }
        usz u=start;
        while (true) {
            usz h=head[u];long old=current[h];current[h]=pts_chain(h,pos,ends,sm,sa);
            if (h==0) break;
            usz p=(usz)parent[h],e=(usz)pedge[h];la[p]=pts_norm(la[p]+eb[e]*(current[h]-old));pts_set(p,pos,lm,la,sm,sa);u=p;
        }
        pts_store(output,8*qi,current[0]);
    }
    return (long)bytes;
}
