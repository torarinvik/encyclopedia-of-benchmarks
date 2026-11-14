const std = @import("std");

const Tree = struct {
    key: [65]i64 = @splat(0),
    height: [65]i32 = @splat(0),
    left: [65]usize = @splat(0),
    right: [65]usize = @splat(0),

    fn nodeHeight(self: *const Tree, node: usize) i32 {
        return if (node == 0) 0 else self.height[node];
    }
    fn refresh(self: *Tree, node: usize) void {
        self.height[node] = 1 + @max(self.nodeHeight(self.left[node]), self.nodeHeight(self.right[node]));
    }
    fn rotateRight(self: *Tree, root: usize) usize {
        const pivot = self.left[root];
        self.left[root] = self.right[pivot]; self.right[pivot] = root;
        self.refresh(root); self.refresh(pivot); return pivot;
    }
    fn rotateLeft(self: *Tree, root: usize) usize {
        const pivot = self.right[root];
        self.right[root] = self.left[pivot]; self.left[pivot] = root;
        self.refresh(root); self.refresh(pivot); return pivot;
    }
    fn balance(self: *Tree, root: usize) usize {
        self.refresh(root);
        const difference = self.nodeHeight(self.left[root]) - self.nodeHeight(self.right[root]);
        if (difference > 1) {
            const child = self.left[root];
            if (self.nodeHeight(self.left[child]) < self.nodeHeight(self.right[child])) self.left[root] = self.rotateLeft(child);
            return self.rotateRight(root);
        }
        if (difference < -1) {
            const child = self.right[root];
            if (self.nodeHeight(self.right[child]) < self.nodeHeight(self.left[child])) self.right[root] = self.rotateRight(child);
            return self.rotateLeft(root);
        }
        return root;
    }
    fn insert(self: *Tree, root: usize, index: usize) usize {
        if (root == 0) return index;
        if (self.key[index] < self.key[root]) self.left[root] = self.insert(self.left[root], index)
        else self.right[root] = self.insert(self.right[root], index);
        return self.balance(root);
    }
    fn erase(self: *Tree, root: usize, key: i64) usize {
        if (root == 0) return 0;
        if (key < self.key[root]) self.left[root] = self.erase(self.left[root], key)
        else if (key > self.key[root]) self.right[root] = self.erase(self.right[root], key)
        else if (self.left[root] == 0) return self.right[root]
        else if (self.right[root] == 0) return self.left[root]
        else {
            var successor = self.right[root];
            while (self.left[successor] != 0) successor = self.left[successor];
            const replacement = self.key[successor];
            self.key[root] = replacement;
            self.right[root] = self.erase(self.right[root], replacement);
        }
        return self.balance(root);
    }
    fn rangeBest(self: *const Tree, root: usize, low: i64, high: i64, x: i64, y: i64, initial: i64) i64 {
        if (root == 0) return initial;
        const key = self.key[root];
        var best = initial;
        if (key >= low) best = self.rangeBest(self.left[root], low, high, x, y, best);
        if (key >= low and key <= high) {
            const dx = x - (@mod(key, 2001) - 1000);
            const dy = y - (@divTrunc(key, 2001) - 1000);
            best = @min(best, dx*dx + dy*dy);
        }
        if (key <= high) best = self.rangeBest(self.right[root], low, high, x, y, best);
        return best;
    }
};

export fn closest_pair_sweep(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 5 or length > 130) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1+2*n) return -1;
    var points: [64]i64 = @splat(0);
    for (0..n) |i| {
        const x = input[1+2*i]; const y = input[2+2*i];
        if (x < -1000 or x > 1000 or y < -1000 or y > 1000) return -1;
        points[i] = (x+1000)*2001+y+1000;
    }
    std.sort.heap(i64, points[0..n], {}, std.sort.asc(i64));
    for (1..n) |i| if (points[i] == points[i-1]) return 0;
    var tree = Tree{};
    var root: usize = 0;
    var oldest: usize = 0;
    var best: i64 = 8000001;
    for (0..n) |i| {
        const x = @divTrunc(points[i],2001)-1000;
        const y = @mod(points[i],2001)-1000;
        while (oldest < i) {
            const old_x = @divTrunc(points[oldest],2001)-1000;
            const dx = x-old_x;
            if (dx*dx <= best) break;
            const old_y = @mod(points[oldest],2001)-1000;
            root = tree.erase(root,(old_y+1000)*2001+old_x+1000);
            oldest += 1;
        }
        var lo: i64 = 0;
        var hi: i64 = 3000;
        while (lo < hi) {
            const middle = @divTrunc(lo+hi+1,2);
            if (middle*middle <= best) lo=middle else hi=middle-1;
        }
        best=tree.rangeBest(root,(y-lo+1000)*2001,(y+lo+1000)*2001+2000,x,y,best);
        const index=i+1;
        tree.key[index]=(y+1000)*2001+x+1000;
        tree.height[index]=1;
        root=tree.insert(root,index);
    }
    return best;
}
