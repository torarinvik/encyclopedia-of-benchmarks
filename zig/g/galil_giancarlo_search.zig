const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const TABLES: usize = 130;

fn preprocess(pattern: *const [TABLES]i64, m: usize, order: *[TABLES]i64,
    next_pos: *[TABLES]i64, shift: *[TABLES]i64) i64 {
    var hmax=[_]i64{0} ** TABLES;
    var kmin=[_]i64{0} ** TABLES;
    var prefix=[_]i64{0} ** TABLES;
    var rmin=[_]i64{0} ** TABLES;
    var i: i64=1; var k: i64=1;
    while (@as(usize,@intCast(k))<=m) {
        while (pattern[@intCast(i)]==pattern[@intCast(i-k)]) i+=1;
        hmax[@intCast(k)]=i;
        var q=k+1;
        while (hmax[@intCast(q-k)]+k<i) { hmax[@intCast(q)]=hmax[@intCast(q-k)]+k; q+=1; }
        k=q;
        if (k==i+1) i=k;
    }
    var x=m;
    while (x>0) : (x-=1) {
        if (@as(usize,@intCast(hmax[x]))<m) kmin[@intCast(hmax[x])]=@intCast(x);
    }
    var r: i64=@intCast(m);
    x=m;
    while (x>0) {
        x-=1;
        if (@as(usize,@intCast(hmax[x+1]))==m) r=@intCast(x+1);
        if (kmin[x]==0) rmin[x]=r;
    }
    var split: i64 = -1;
    r=@intCast(m);
    for (0..m) |index| {
        if (kmin[index]==0) { r-=1; order[@intCast(r)]=@intCast(index); }
        else { split+=1; order[@intCast(split)]=@intCast(index); }
    }
    for (0..@as(usize,@intCast(split+1))) |index| shift[index]=kmin[@intCast(order[index])];
    for (@as(usize,@intCast(split+1))..m) |index| shift[index]=rmin[@intCast(order[index])];
    shift[m]=rmin[0];
    var count: i64=0;
    for (0..m) |index| { prefix[index]=count; if (kmin[index]>0) count+=1; }
    for (0..@as(usize,@intCast(split+1))) |index| {
        const pos: usize=@intCast(order[index]);
        next_pos[index]=prefix[@intCast(order[index]-kmin[pos])];
    }
    for (@as(usize,@intCast(split+1))..m) |index| {
        next_pos[index]=prefix[m-@as(usize,@intCast(rmin[@intCast(order[index])]))];
    }
    next_pos[m]=prefix[m-@as(usize,@intCast(rmin[@intCast(order[m-1])]))];
    return split;
}

fn search(text: *const [MAX_TEXT]i64, n: usize, pattern: *const [TABLES]i64, m: usize) i64 {
    var ell: usize=0;
    while (ell+1<m and pattern[ell+1]==pattern[0]) ell+=1;
    var matches: i64=0; var sum: i64=0; var xor_sum: i64=0;
    if (ell==m-1) {
        var run: usize=0;
        for (0..n) |position| {
            if (text[position]==pattern[0]) run+=1 else run=0;
            if (run>=m) { const start: i64=@intCast(position+1-m); matches+=1; sum+=start; xor_sum^=start; }
        }
        return (matches<<36)|(sum<<12)|xor_sum;
    }
    var order=[_]i64{0} ** TABLES;
    var next_pos=[_]i64{0} ** TABLES;
    var shift=[_]i64{0} ** TABLES;
    const nd=preprocess(pattern,m,&order,&next_pos,&shift);
    if (n<m) return 0;
    var i: i64=0; var j: i64=0; var last: i64 = -1; var heavy=false;
    while (@as(usize,@intCast(j))<=n-m) {
        if (heavy and i==0) {
            var k=last-j+1;
            while (@as(usize,@intCast(j+k))<n and pattern[0]==text[@intCast(j+k)]) k+=1;
            if (@as(usize,@intCast(k))<=ell or @as(usize,@intCast(j+k))>=n or
                pattern[ell+1]!=text[@intCast(j+k)]) {
                i=0; j+=k+1; last=j-1;
            } else { i=1; last=j+k; j=last-@as(i64,@intCast(ell+1)); }
        } else {
            while (@as(usize,@intCast(i))<m and last<j+order[@intCast(i)] and
                pattern[@intCast(order[@intCast(i)])]==text[@intCast(j+order[@intCast(i)])]) i+=1;
            if (@as(usize,@intCast(i))>=m or last>=j+order[@intCast(i)]) {
                matches+=1; sum+=j; xor_sum^=j; i=@intCast(m);
            }
            if (i>nd) last=j+@as(i64,@intCast(m))-1;
            j+=shift[@intCast(i)]; i=next_pos[@intCast(i)];
        }
        heavy=j<=last;
    }
    (matches<<36)|(sum<<12)|xor_sum
}

export fn galil_giancarlo_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt==null or length<2 or length>MAX_INPUT) return -1;
    const input=input_opt.?;
    const nv=input[0]; const mv=input[1];
    if (nv<0 or nv>@as(i64,@intCast(MAX_TEXT)) or mv<1 or mv>@as(i64,@intCast(MAX_PATTERN))) return -1;
    const n: usize=@intCast(nv); const m: usize=@intCast(mv);
    if (length!=2+n+m) return -1;
    var text=[_]i64{0} ** MAX_TEXT;
    var pattern=[_]i64{0} ** TABLES;
    for (0..n) |index| { const symbol=input[2+index]; if (symbol<0 or symbol>3) return -1; text[index]=symbol; }
    for (0..m) |index| { const symbol=input[2+n+index]; if (symbol<0 or symbol>3) return -1; pattern[index]=symbol; }
    pattern[m]=4;
    return search(&text,n,&pattern,m);
}
