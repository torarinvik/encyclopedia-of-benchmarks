// Clean-room bounded deterministic Sequitur grammar profile.
const Grammar = struct {
    symbols: [16384]i32 = [_]i32{0} ** 16384,
    lengths: [256]usize = [_]usize{0} ** 256,
    live: [256]bool = [_]bool{false} ** 256,
    next_rule: usize = 1,
};
const Duplicate = struct { found: bool = false, r1:usize=0, p1:usize=0, r2:usize=0, p2:usize=0, left:i32=0, right:i32=0 };

fn replace_pair(g: *Grammar, rule:usize, position:usize, token:i32) void {
    var i=position+2;
    while (i<g.lengths[rule]) : (i+=1) g.symbols[rule*64+i-1]=g.symbols[rule*64+i];
    g.lengths[rule]-=1;
    g.symbols[rule*64+position]=token;
}

fn find_duplicate(g: *const Grammar) Duplicate {
    var r1:usize=0;
    while (r1<g.next_rule) : (r1+=1) {
        if (!g.live[r1]) continue;
        var p1:usize=0;
        while (p1+1<g.lengths[r1]) : (p1+=1) {
            const left=g.symbols[r1*64+p1]; const right=g.symbols[r1*64+p1+1];
            var r2=r1;
            while (r2<g.next_rule) : (r2+=1) {
                if (!g.live[r2]) continue;
                var p2:usize=if (r2==r1) p1+2 else 0;
                while (p2+1<g.lengths[r2]) : (p2+=1) {
                    if (g.symbols[r2*64+p2]==left and g.symbols[r2*64+p2+1]==right)
                        return .{.found=true,.r1=r1,.p1=p1,.r2=r2,.p2=p2,.left=left,.right=right};
                }
            }
        }
    }
    return .{};
}

fn cleanup_one(g: *Grammar) bool {
    var target:usize=1;
    while (target<g.next_rule) : (target+=1) {
        if (!g.live[target]) continue;
        var count:usize=0; var parent:usize=0; var position:usize=0;
        const token:i32=256+@as(i32,@intCast(target));
        for (0..g.next_rule) |rule| {
            if (g.live[rule]) for (0..g.lengths[rule]) |i| {
                if (g.symbols[rule*64+i]==token) {count+=1;parent=rule;position=i;}
            };
        }
        if (count==0) {g.live[target]=false;g.lengths[target]=0;return true;}
        if (count==1) {
            var copy:[64]i32=undefined; const replacement_length=g.lengths[target];
            for (0..replacement_length) |i| copy[i]=g.symbols[target*64+i];
            const delta:isize=@as(isize,@intCast(replacement_length))-1;
            const old_length=g.lengths[parent]; var i=old_length;
            while (i>position+1) {i-=1;const destination=@as(usize,@intCast(@as(isize,@intCast(i))+delta));g.symbols[parent*64+destination]=g.symbols[parent*64+i];}
            for (0..replacement_length) |i2| g.symbols[parent*64+position+i2]=copy[i2];
            g.lengths[parent]=@intCast(@as(isize,@intCast(old_length))+delta);
            g.live[target]=false;g.lengths[target]=0;return true;
        }
    }
    return false;
}

fn normalize(g: *Grammar) void {
    while (true) {
        while (cleanup_one(g)) {}
        const d=find_duplicate(g); if (!d.found) return;
        var existing:?usize=null;
        var rule:usize=1;
        while (rule<g.next_rule) : (rule+=1) {
            if (g.live[rule] and g.lengths[rule]==2 and g.symbols[rule*64]==d.left and g.symbols[rule*64+1]==d.right) {existing=rule;break;}
        }
        if (existing) |old| {
            var target=d.r1; var position=d.p1;
            if (target==old and position==0) {target=d.r2;position=d.p2;}
            replace_pair(g,target,position,256+@as(i32,@intCast(old)));
        } else {
            const fresh=g.next_rule;g.next_rule+=1;g.live[fresh]=true;g.lengths[fresh]=2;
            g.symbols[fresh*64]=d.left;g.symbols[fresh*64+1]=d.right;
            const token=256+@as(i32,@intCast(fresh));
            replace_pair(g,d.r2,d.p2,token);replace_pair(g,d.r1,d.p1,token);
        }
    }
}

export fn sequitur_grammar_induction(input_opt:?[*]const i64, length:usize) i64 {
    if (input_opt==null or length<1 or length>66) return -1;
    const input=input_opt.?;
    if (input[0]<0 or input[0]>64 or length!=@as(usize,@intCast(input[0]))+1) return -1;
    const n:usize=@intCast(input[0]);
    for (0..n) |i| if (input[i+1]<0 or input[i+1]>255) return -1;
    var g=Grammar{};g.live[0]=true;
    for (0..n) |i| {g.symbols[g.lengths[0]]=@intCast(input[i+1]);g.lengths[0]+=1;normalize(&g);}
    var rules:i64=0;var symbols:i64=0;
    for (0..g.next_rule) |r| if (g.live[r]) {if (r!=0) rules+=1;symbols+=@intCast(g.lengths[r]);};
    return 1000*rules+symbols;
}
