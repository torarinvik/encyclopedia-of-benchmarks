// Independent suffix-array/LCP draft; compilation and output are unverified.
const std = @import("std");

fn suffixBefore(a: usize, b: usize, step: usize, classes: []const usize) bool {
    if (classes[a]!=classes[b]) return classes[a]<classes[b];
    const aa=if (a+step<classes.len) classes[a+step] else 0;
    const bb=if (b+step<classes.len) classes[b+step] else 0;
    return aa<bb;
}
fn sortSuffixes(sa: []usize, scratch: []usize, step: usize, classes: []const usize) void {
    var width: usize=1;
    while (width<sa.len) : (width*=2) {
        var start: usize=0;
        while (start<sa.len) {
            const mid=@min(start+width,sa.len); const end=@min(start+2*width,sa.len);
            var a=start; var b=mid; var out=start;
            while (a<mid and b<end) : (out+=1) {
                if (suffixBefore(sa[b],sa[a],step,classes)) { scratch[out]=sa[b]; b+=1; }
                else { scratch[out]=sa[a]; a+=1; }
            }
            while (a<mid) : (out+=1) { scratch[out]=sa[a]; a+=1; }
            while (b<end) : (out+=1) { scratch[out]=sa[b]; b+=1; }
            start=end;
        }
        @memcpy(sa,scratch);
    }
}
const Compare = struct {
    starts: []const usize, sizes: []const usize, text: []const usize,
    rank: []const usize, logs: []const usize, table: []const usize, n: usize,
    fn common(self: Compare, a: usize, b: usize, limit: usize) usize {
        if (a==b) return limit;
        const lo=@min(self.rank[a],self.rank[b])+1; const hi=@max(self.rank[a],self.rank[b]);
        const level=self.logs[hi-lo+1]; const span=@as(usize,1) << @intCast(level);
        return @min(limit,@min(self.table[level*self.n+lo],self.table[level*self.n+hi-span+1]));
    }
    fn before(self: Compare, a: usize, b: usize) bool {
        const left=[_]usize{a,b}; const right=[_]usize{b,a};
        var li: usize=0; var ri: usize=0; var lp: usize=0; var rp: usize=0;
        while (li<2 and ri<2) {
            const lw=left[li]; const rw=right[ri];
            const limit=@min(self.sizes[lw]-lp,self.sizes[rw]-rp);
            const x=self.starts[lw]+lp; const y=self.starts[rw]+rp;
            const same=self.common(x,y,limit);
            if (same<limit) return self.text[x+same]<self.text[y+same];
            lp+=same; rp+=same;
            if (lp==self.sizes[lw]) { li+=1; lp=0; }
            if (rp==self.sizes[rw]) { ri+=1; rp=0; }
        }
        return a<b;
    }
};
fn sortWords(order: []usize, scratch: []usize, context: Compare) void {
    var width: usize=1;
    while (width<order.len) : (width*=2) {
        var start: usize=0;
        while (start<order.len) {
            const mid=@min(start+width,order.len); const end=@min(start+2*width,order.len);
            var a=start; var b=mid; var out=start;
            while (a<mid and b<end) : (out+=1) {
                if (context.before(order[b],order[a])) { scratch[out]=order[b]; b+=1; }
                else { scratch[out]=order[a]; a+=1; }
            }
            while (a<mid) : (out+=1) { scratch[out]=order[a]; a+=1; }
            while (b<end) : (out+=1) { scratch[out]=order[b]; b+=1; }
            start=end;
        }
        @memcpy(order,scratch);
    }
}

export fn lexicographically_minimal_concatenation(input_opt: ?[*]const i64, length: usize,
                                                    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt==null or length==0) return -1;
    const input=input_opt.?[0..length];
    if (input[0]<0 or input[0]>16384) return -1;
    const count: usize=@intCast(input[0]);
    var offset: usize=1; var total: usize=0;
    for (0..count) |_| {
        if (offset>=length or input[offset]<1 or input[offset]>65536) return -1;
        const size: usize=@intCast(input[offset]); offset+=1;
        if (size>65536-total or size>length-offset) return -1;
        for (input[offset..offset+size]) |value| if (value<97 or value>122) return -1;
        offset+=size; total+=size;
    }
    if (offset!=length) return -1;
    if (output_opt==null or capacity<total) return -2;
    if (count==0) return 0;
    const n=total+count;
    var levels: usize=1;
    while ((@as(usize,1) << @intCast(levels))<=n) levels+=1;
    const alloc=std.heap.page_allocator;
    const memory=alloc.alloc(usize,(7+levels)*n+1+4*count) catch return -1;
    defer alloc.free(memory);
    @memset(memory,0);
    const text=memory[0..n]; const sa=memory[n..2*n]; const scratch=memory[2*n..3*n];
    var classes=memory[3*n..4*n]; var next=memory[4*n..5*n];
    const rank=memory[5*n..6*n]; const logs=memory[6*n..7*n+1];
    const table=memory[7*n+1..(7+levels)*n+1];
    const base=(7+levels)*n+1;
    const starts=memory[base..base+count]; const sizes=memory[base+count..base+2*count];
    const order=memory[base+2*count..base+3*count]; const word_scratch=memory[base+3*count..];
    offset=1; var used: usize=0;
    for (0..count) |i| {
        const size: usize=@intCast(input[offset]); offset+=1;
        starts[i]=used; sizes[i]=size;
        for (input[offset..offset+size]) |value| { text[used]=@intCast(value); used+=1; }
        offset+=size; text[used]=0; used+=1;
    }
    for (0..n) |i| { sa[i]=i; classes[i]=text[i]+1; }
    var step: usize=1;
    while (step<n) : (step*=2) {
        sortSuffixes(sa,scratch,step,classes);
        next[sa[0]]=1;
        for (1..n) |i| next[sa[i]]=next[sa[i-1]]+@intFromBool(suffixBefore(sa[i-1],sa[i],step,classes));
        const temp=classes; classes=next; next=temp;
        if (classes[sa[n-1]]==n) break;
    }
    for (0..n) |i| rank[sa[i]]=i;
    var shared: usize=0;
    for (0..n) |i| {
        const r=rank[i];
        if (r==0) { shared=0; continue; }
        const j=sa[r-1];
        while (i+shared<n and j+shared<n and text[i+shared]==text[j+shared]) shared+=1;
        table[r]=shared;
        if (shared>0) shared-=1;
    }
    for (2..n+1) |i| logs[i]=logs[i/2]+1;
    for (1..levels) |level| {
        const width=@as(usize,1) << @intCast(level); const half=width/2;
        for (0..n-width+1) |i| table[level*n+i]=@min(table[(level-1)*n+i],table[(level-1)*n+i+half]);
    }
    for (0..count) |i| order[i]=i;
    sortWords(order,word_scratch,Compare{.starts=starts,.sizes=sizes,.text=text,.rank=rank,.logs=logs,.table=table,.n=n});
    const output=output_opt.?;
    var written: usize=0;
    for (order) |word| for (0..sizes[word]) |j| {
        output[written]=@intCast(text[starts[word]+j]); written+=1;
    };
    return @intCast(written);
}
