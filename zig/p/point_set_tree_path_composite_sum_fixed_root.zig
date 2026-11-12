const N: usize = 16;
const Q: usize = 32;
const BASE: usize = 16;
const INPUT_MAX: usize = 5 * N + 4 * Q - 2;
const MOD: i64 = 998_244_353;
const Affine = struct { m: i64, a: i64 };

fn norm(x: i64) i64 { return @mod(x, MOD); }
fn compose(l: Affine, r: Affine) Affine {
    return .{ .m = l.m * r.m % MOD, .a = (l.m * r.a + l.a) % MOD };
}
fn findRoot(parent: *[N]usize, item: usize) usize {
    var x = item;
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}
fn setLeaf(seg: *[2 * BASE]Affine, pos: *const [N]usize,
    mul: *const [N]i64, add: *const [N]i64, u: usize) void {
    var k = BASE + pos[u];
    seg[k] = .{ .m = mul[u], .a = add[u] };
    k /= 2;
    while (k > 0) { seg[k] = compose(seg[2*k], seg[2*k+1]); k /= 2; }
}
fn chainValue(seg: *const [2 * BASE]Affine, pos: *const [N]usize,
    ends: *const [N]usize, h: usize) i64 {
    var l = BASE + pos[h]; var r = BASE + ends[h];
    var left = Affine{ .m = 1, .a = 0 }; var right = left;
    while (l < r) {
        if ((l & 1) == 1) { left = compose(left, seg[l]); l += 1; }
        if ((r & 1) == 1) { r -= 1; right = compose(seg[r], right); }
        l /= 2; r /= 2;
    }
    return compose(left, right).a;
}
fn storeLe(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| out[at+i] = @truncate(bits >> @intCast(8*i));
}

export fn point_set_tree_path_composite_sum_fixed_root(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > INPUT_MAX) return -1;
    const input = input_opt.?;
    const nr = input[0]; const qr = input[1];
    if (nr < 1 or nr > @as(i64, @intCast(N)) or qr < 1 or qr > @as(i64, @intCast(Q))) return -1;
    const n: usize = @intCast(nr); const q: usize = @intCast(qr);
    var cur: usize = 2;
    var value: [N]i64 = @splat(0);
    for (0..n) |u| { if (cur >= length) return -1; value[u]=input[cur];cur+=1;if(value[u]<0 or value[u]>=MOD)return -1; }
    var edge_at: [N][N]i32 = undefined;
    for (0..N) |u| for (0..N) |v| { edge_at[u][v] = -1; };
    var eu: [N-1]usize = @splat(0); var ev: [N-1]usize = @splat(0);
    var eb: [N-1]i64 = @splat(0); var ec: [N-1]i64 = @splat(0);
    var dsu: [N]usize = undefined; var dsz: [N]usize = @splat(0);
    for (0..n) |u| { dsu[u]=u;dsz[u]=1; }
    for (0..n-1) |e| {
        if (cur+4>length)return -1;
        const ur=input[cur];const vr=input[cur+1];const b=input[cur+2];const c=input[cur+3];cur+=4;
        if(ur<0 or ur>=nr or vr<0 or vr>=nr or ur==vr or b<1 or b>=MOD or c<0 or c>=MOD)return -1;
        const u:usize=@intCast(ur);const v:usize=@intCast(vr);var ru=findRoot(&dsu,u);var rv=findRoot(&dsu,v);
        if(ru==rv)return -1;if(dsz[ru]<dsz[rv]){const t=ru;ru=rv;rv=t;}dsu[rv]=ru;dsz[ru]+=dsz[rv];
        eu[e]=u;ev[e]=v;eb[e]=b;ec[e]=c;edge_at[u][v]=@intCast(e);edge_at[v][u]=@intCast(e);
    }
    const Op=struct{kind:i64,x:i64,y:i64,z:i64};
    var ops:[Q]Op=@splat(.{.kind=0,.x=0,.y=0,.z=0});
    for(0..q)|i|{if(cur>=length)return -1;const kind=input[cur];cur+=1;
        if(kind==0){if(cur+2>length)return -1;const x=input[cur];const y=input[cur+1];cur+=2;if(x<0 or x>=nr or y<0 or y>=MOD)return -1;ops[i]=.{.kind=kind,.x=x,.y=y,.z=0};}
        else if(kind==1){if(cur+3>length)return -1;const x=input[cur];const y=input[cur+1];const z=input[cur+2];cur+=3;if(x<0 or x>=nr-1 or y<1 or y>=MOD or z<0 or z>=MOD)return -1;ops[i]=.{.kind=kind,.x=x,.y=y,.z=z};}
        else return -1;
    }
    if(cur!=length)return -1;const bytes=8*q;if(output_opt==null or capacity<bytes)return -2;
    var parent:[N]i64=@splat(-2);var pedge:[N]i64=@splat(-1);var order:[N]usize=@splat(0);var stack:[N]usize=@splat(0);
    var count:usize=0;var top:usize=1;parent[0] = -1;stack[0]=0;
    while(top>0){top-=1;const u=stack[top];order[count]=u;count+=1;for(0..n)|v|{if(edge_at[u][v]>=0 and @as(i64,@intCast(v))!=parent[u]){parent[v]=@intCast(u);pedge[v]=edge_at[u][v];stack[top]=v;top+=1;}}}
    var sub:[N]usize=@splat(1);var heavy:[N]i64=@splat(-1);
    var ii=count;while(ii>0){ii-=1;const u=order[ii];var best:usize=0;for(0..n)|v|{if(parent[v]==@as(i64,@intCast(u))){sub[u]+=sub[v];if(sub[v]>best or (sub[v]==best and (heavy[u]<0 or v<@as(usize,@intCast(heavy[u])))){best=sub[v];heavy[u]=@intCast(v);}}}}
    var head:[N]usize=@splat(0);var pos:[N]usize=@splat(0);var ends:[N]usize=@splat(0);var hs:[N]usize=@splat(0);var timer:usize=0;top=1;hs[0]=0;
    while(top>0){top-=1;const h=hs[top];var u=h;while(true){head[u]=h;pos[u]=timer;timer+=1;for(0..n)|v|{if(parent[v]==@as(i64,@intCast(u)) and heavy[u]!=@as(i64,@intCast(v))){hs[top]=v;top+=1;}}if(heavy[u]<0)break;u=@intCast(heavy[u]);}ends[h]=timer;}
    var down:[N]i64=@splat(0);ii=count;while(ii>0){ii-=1;const u=order[ii];down[u]=value[u];for(0..n)|v|{if(parent[v]==@as(i64,@intCast(u))){const e:usize=@intCast(pedge[v]);down[u]+=eb[e]*down[v]+ec[e]*@as(i64,@intCast(sub[v]));}}down[u]=@mod(down[u],MOD);}
    var mul:[N]i64=@splat(0);var add:[N]i64=@splat(0);for(0..n)|u|{add[u]=value[u];for(0..n)|v|{if(parent[v]==@as(i64,@intCast(u))){const e:usize=@intCast(pedge[v]);if(heavy[u]==@as(i64,@intCast(v))){mul[u]=eb[e];add[u]+=ec[e]*@as(i64,@intCast(sub[v]));}else{add[u]+=eb[e]*down[v]+ec[e]*@as(i64,@intCast(sub[v]));}}}add[u]=@mod(add[u],MOD);}
    var seg:[2*BASE]Affine=@splat(.{.m=1,.a=0});for(0..n)|u|seg[BASE+pos[u]] = .{.m=mul[u],.a=add[u]};ii=BASE;while(ii>1){ii-=1;seg[ii]=compose(seg[2*ii],seg[2*ii+1]);}
    var current:[N]i64=@splat(0);for(0..n)|u|{if(head[u]==u)current[u]=down[u];}
    const output=output_opt.?;
    for(0..q)|qi|{const op=ops[qi];var start:usize=0;
        if(op.kind==0){const u:usize=@intCast(op.x);add[u]=norm(add[u]+op.y-value[u]);value[u]=op.y;setLeaf(&seg,&pos,&mul,&add,u);start=u;}
        else{const e:usize=@intCast(op.x);const u=eu[e];const v=ev[e];const child=if(parent[u]==@as(i64,@intCast(v)))u else v;const p:usize=@intCast(parent[child]);const ob=eb[e];const oc=ec[e];if(heavy[p]==@as(i64,@intCast(child))){mul[p]=op.y;add[p]=norm(add[p]+(op.z-oc)*@as(i64,@intCast(sub[child])));}else{add[p]=norm(add[p]+(op.y-ob)*current[child]+(op.z-oc)*@as(i64,@intCast(sub[child])));}eb[e]=op.y;ec[e]=op.z;setLeaf(&seg,&pos,&mul,&add,p);start=p;}
        var u=start;while(true){const h=head[u];const old=current[h];current[h]=chainValue(&seg,&pos,&ends,h);if(h==0)break;const p:usize=@intCast(parent[h]);const e:usize=@intCast(pedge[h]);add[p]=norm(add[p]+eb[e]*(current[h]-old));setLeaf(&seg,&pos,&mul,&add,p);u=p;}
        storeLe(output,8*qi,current[0]);
    }
    return @intCast(bytes);
}
