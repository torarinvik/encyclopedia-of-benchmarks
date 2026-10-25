const std = @import("std");
const MAX_POINTS: usize = 5;
const MAX_EDGES: usize = 32;
const SCALE: f64 = 1000.0;
const Point = struct { x: f64, y: f64, norm: f64 };
const EdgePair = struct { left: i32, right: i32 };
const Center = struct { x: f64, y: f64 };
const State = struct {
    points: [MAX_POINTS]Point,
    left: [MAX_POINTS]i32,
    right: [MAX_POINTS]i32,
    onext: [MAX_EDGES * 4]i32,
    origin: [MAX_EDGES * 4]i32,
    alive: [MAX_EDGES]bool,
    edge_count: usize,

    fn init() State {
        return .{ .points = [_]Point{.{ .x = 0, .y = 0, .norm = 0 }} ** MAX_POINTS,
            .left = [_]i32{-1} ** MAX_POINTS, .right = [_]i32{-1} ** MAX_POINTS,
            .onext = [_]i32{0} ** (MAX_EDGES * 4), .origin = [_]i32{0} ** (MAX_EDGES * 4),
            .alive = [_]bool{false} ** MAX_EDGES, .edge_count = 0 };
    }
    fn sym(e: i32) i32 { return e ^ 2; }
    fn rot(e: i32) i32 { return (e & ~@as(i32, 3)) | ((e + 1) & 3); }
    fn rotinv(e: i32) i32 { return (e & ~@as(i32, 3)) | ((e + 3) & 3); }
    fn lnext(self: *const State, e: i32) i32 { return rot(self.onext[@intCast(rotinv(e))]); }
    fn oprev(self: *const State, e: i32) i32 { return rot(self.onext[@intCast(rot(e))]); }
    fn rprev(self: *const State, e: i32) i32 { return self.onext[@intCast(sym(e))]; }
    fn lprev(self: *const State, e: i32) i32 { return sym(self.onext[@intCast(e)]); }
    fn orig(self: *const State, e: i32) i32 { return self.origin[@intCast(e)]; }
    fn dest(self: *const State, e: i32) i32 { return self.origin[@intCast(sym(e))]; }
    fn ccw(self: *const State, ai: i32, bi: i32, ci: i32) bool {
        const a=self.points[@intCast(ai)]; const b=self.points[@intCast(bi)]; const c=self.points[@intCast(ci)];
        return (a.x-c.x)*(b.y-c.y)-(b.x-c.x)*(a.y-c.y)>0.0;
    }
    fn incircle(self: *const State, ai: i32, bi: i32, ci: i32, di: i32) bool {
        const a=self.points[@intCast(ai)];const b=self.points[@intCast(bi)];const c=self.points[@intCast(ci)];const d=self.points[@intCast(di)];
        const adx=a.x-d.x;const ady=a.y-d.y;const bdx=b.x-d.x;const bdy=b.y-d.y;const cdx=c.x-d.x;const cdy=c.y-d.y;
        const result=(a.norm-d.norm)*(bdx*cdy-bdy*cdx)+(b.norm-d.norm)*(cdx*ady-cdy*adx)+(c.norm-d.norm)*(adx*bdy-ady*bdx);return result>0.0;
    }
    fn makeEdge(self: *State, a: i32, b: i32) i32 {
        const e: i32=@intCast(self.edge_count*4);self.edge_count+=1;self.alive[@intCast(e/4)]=true;
        self.onext[@intCast(e)]=e;self.origin[@intCast(e)]=a;self.onext[@intCast(e+1)]=e+3;
        self.onext[@intCast(e+2)]=e+2;self.origin[@intCast(e+2)]=b;self.onext[@intCast(e+3)]=e+1;return e;
    }
    fn splice(self: *State, a: i32, b: i32) void {
        const alpha=rot(self.onext[@intCast(a)]);const beta=rot(self.onext[@intCast(b)]);
        var t1=self.onext[@intCast(beta)];var temp=self.onext[@intCast(alpha)];self.onext[@intCast(alpha)]=t1;self.onext[@intCast(beta)]=temp;
        temp=self.onext[@intCast(a)];t1=self.onext[@intCast(b)];self.onext[@intCast(b)]=temp;self.onext[@intCast(a)]=t1;
    }
    fn connectLeft(self: *State, a: i32, b: i32) i32 { const e=self.makeEdge(self.dest(a),self.orig(b));self.splice(e,self.lnext(a));self.splice(sym(e),b);return e; }
    fn connectRight(self: *State, a: i32, b: i32) i32 { const e=self.makeEdge(self.dest(a),self.orig(b));self.splice(e,sym(a));self.splice(sym(e),self.oprev(b));return e; }
    fn deleteEdge(self: *State, e: i32) void { var f=self.oprev(e);self.splice(e,f);f=self.oprev(sym(e));self.splice(sym(e),f);self.alive[@intCast(e/4)]=false; }
    fn valid(self: *const State, l: i32, base: i32) bool { return self.ccw(self.orig(base),self.dest(l),self.dest(base)); }
    fn merge(self: *State, ldo: i32, ldi0: i32, rdi0: i32, rdo0: i32) EdgePair {
        var ldi=ldi0;var rdi=rdi0;var rdo=rdo0;
        while (true) { const t3=self.orig(rdi);var t1=self.orig(ldi);var t2=self.dest(ldi);while(self.ccw(t1,t2,t3)){ldi=self.lnext(ldi);t1=self.orig(ldi);t2=self.dest(ldi);}t2=self.dest(rdi);if(self.ccw(t2,t3,t1)){rdi=self.rprev(rdi);}else{break;} }
        var basel=self.connectLeft(sym(rdi),ldi);var lcand=self.rprev(basel);var rcand=self.oprev(basel);var left_outer=ldo;
        const t1=self.orig(basel);const t2=self.dest(basel);if(t1==self.orig(rdo))rdo=basel;if(t2==self.orig(left_outer))left_outer=sym(basel);
        while(true){var t=self.onext[@intCast(lcand)];if(self.valid(t,basel)){const v4=self.orig(basel);var v1=self.dest(lcand);const v3=self.orig(lcand);var v2=self.dest(t);while(self.incircle(v1,v2,v3,v4)){self.deleteEdge(lcand);lcand=t;t=self.onext[@intCast(lcand)];v1=self.dest(lcand);v2=self.dest(t);}}
            t=self.oprev(rcand);if(self.valid(t,basel)){const v4=self.dest(basel);var v1=self.dest(t);var v2=self.dest(rcand);const v3=self.orig(rcand);while(self.incircle(v1,v2,v3,v4)){self.deleteEdge(rcand);rcand=t;t=self.oprev(rcand);v2=self.dest(rcand);v1=self.dest(t);}}
            const lv=self.valid(lcand,basel);const rv=self.valid(rcand,basel);if(!lv and !rv)return .{.left=left_outer,.right=rdo};
            const v1=self.dest(lcand);const v2=self.orig(lcand);const v3=self.orig(rcand);const v4=self.dest(rcand);
            if(!lv or (rv and self.incircle(v1,v2,v3,v4))){basel=self.connectLeft(rcand,sym(basel));rcand=self.lnext(sym(basel));}else{basel=sym(self.connectRight(lcand,basel));lcand=self.rprev(basel);}
        }
    }
    fn getLow(self: *const State, node0: i32) i32 { var node=node0;while(self.left[@intCast(node)]>=0)node=self.left[@intCast(node)];return node; }
    fn build(self: *State, tree: i32, extra: i32) EdgePair {
        if(tree>=0 and self.right[@intCast(tree)]>=0){const minx=self.getLow(tree);const dr=self.build(self.right[@intCast(tree)],extra);const dl=self.build(self.left[@intCast(tree)],tree);var result=self.merge(dl.left,dl.right,dr.left,dr.right);while(self.orig(result.left)!=minx)result.left=self.rprev(result.left);while(self.orig(result.right)!=extra)result.right=self.lprev(result.right);return result;}
        if(tree<0)return .{.left=-1,.right=-1};if(self.left[@intCast(tree)]<0){const e=self.makeEdge(tree,extra);return .{.left=e,.right=sym(e)};}
        const s1=self.left[@intCast(tree)];const s2=tree;const s3=extra;const a=self.makeEdge(s1,s2);const b=self.makeEdge(s2,s3);self.splice(sym(a),b);const c=self.connectLeft(b,a);if(self.ccw(s1,s3,s2))return .{.left=sym(c),.right=c};const result=EdgePair{.left=a,.right=sym(b)};if(!self.ccw(s1,s2,s3))self.deleteEdge(c);return result;
    }
    fn center(self: *const State, ai: i32, bi: i32, ci: i32) Center { const a=self.points[@intCast(ai)];const b=self.points[@intCast(bi)];const c=self.points[@intCast(ci)];const vx=b.x-a.x;const vy=b.y-a.y;const wx=c.x-a.x;const wy=c.y-a.y;const d3=vx*wy-vy*wx;const d2=-2.0*d3;const d4=(c.x-b.x)*wx+(c.y-b.y)*wy;return .{.x=0.5*(a.x+b.x)+(d4/d2)*vy,.y=0.5*(a.y+b.y)-(d4/d2)*vx}; }
    fn faceCenter(self: *const State, e: i32) ?Center { const e2=self.lnext(e);const e3=self.lnext(e2);if(self.lnext(e3)!=e)return null;const a=self.orig(e);const b=self.dest(e);const c=self.dest(e2);if(a==b or b==c or a==c or !self.ccw(a,b,c))return null;return self.center(a,b,c); }
};
fn quantize(value: f64) i64 { return @intFromFloat(@floor(value*SCALE+0.5)); }

export fn olden_voronoi(input: [*c]const i64, length: usize) i64 {
    if(input==null or (length!=7 and length!=11))return -1;const n64=input[0];if(n64!=3 and n64!=5)return -1;const n:usize=@intCast(n64);if(length!=1+2*n)return -1;
    var s=State.init();for(0..n)|i|{const x=input[1+2*i];const y=input[2+2*i];if(x< -8 or x>8 or y< -8 or y>8)return -1;if(i>0 and input[1+2*(i-1)]>=x)return -1;s.points[i]=.{.x=@floatFromInt(x),.y=@floatFromInt(y),.norm=@floatFromInt(x*x+y*y)};}
    if(n==3){s.left[1]=0;}else{s.left[2]=1;s.right[2]=3;s.left[1]=0;}
    for(0..n)|a|{for(a+1..n)|b|{for(b+1..n)|c|{if(!s.ccw(@intCast(a),@intCast(b),@intCast(c)) and !s.ccw(@intCast(a),@intCast(c),@intCast(b)))return -1;}}}
    if(n==5){for(0..n)|a|{for(a+1..n)|b|{for(b+1..n)|c|{for(c+1..n)|d|{if(!s.incircle(@intCast(a),@intCast(b),@intCast(c),@intCast(d)) and !s.incircle(@intCast(a),@intCast(c),@intCast(b),@intCast(d)))return -1;}}}}}
    _=s.build(if(n==3) 1 else 2,@intCast(n-1));var seen: [16][3]i32 = [_][3]i32{.{0,0,0}} ** 16;var faces:i64=0;var edges:i64=0;var dual:i64=0;var rays:i64=0;var projection:i64=0;
    for(0..s.edge_count)|edge|{if(s.alive[edge]){const e:i32=@intCast(edge*4);const left=s.faceCenter(e);if(left)|center|{const a=s.orig(e);const b=s.dest(e);const c=s.dest(s.lnext(e));var duplicate=false;for(0..@intCast(faces))|f|{if((seen[f][0]==a or seen[f][1]==a or seen[f][2]==a) and (seen[f][0]==b or seen[f][1]==b or seen[f][2]==b) and (seen[f][0]==c or seen[f][1]==c or seen[f][2]==c))duplicate=true;}if(!duplicate){seen[@intCast(faces)]=.{a,b,c};faces+=1;projection+=quantize(center.x)+2*quantize(center.y);}}
        const right=s.faceCenter(State.sym(e));if(left!=null or right!=null){edges+=1;if(left!=null and right!=null){dual+=1;}else{rays+=1;}}}}
    return projection+100*faces+10*dual+rays+edges;
}
