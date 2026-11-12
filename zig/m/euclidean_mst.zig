const MAX_POINTS: usize = 8;
const MAX_EDGES: usize = MAX_POINTS * (MAX_POINTS - 1) / 2;
const MAX_INPUT_LENGTH: usize = 18;
const MAX_OUTPUT_WORDS: usize = 2 * MAX_POINTS - 1;

const Point = struct { x: i64, y: i64 };
const Edge = struct { u: usize, v: usize, weight: i64 };

fn orientation(a: Point, b: Point, c: Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
fn incircle(a: Point, b: Point, c: Point, d: Point) i64 {
	const ax=a.x-d.x; const ay=a.y-d.y; const bx=b.x-d.x; const by=b.y-d.y; const cx=c.x-d.x; const cy=c.y-d.y;
	return (ax*ax+ay*ay)*(bx*cy-by*cx) - (bx*bx+by*by)*(ax*cy-ay*cx) + (cx*cx+cy*cy)*(ax*by-ay*bx);
}
fn generalPosition(points: [MAX_POINTS]Point, n: usize) bool {
	for (0..n) |a| for (a+1..n) |b| {
		if (points[a].x == points[b].x and points[a].y == points[b].y) return false;
	};
	for (0..n) |a| for (a+1..n) |b| for (b+1..n) |c| {
		if (orientation(points[a], points[b], points[c]) == 0) return false;
		for (0..n) |d| {
			if (d != a and d != b and d != c and incircle(points[a], points[b], points[c], points[d]) == 0) return false;
		}
	};
	return true;
}
fn findRoot(parent: *[MAX_POINTS]usize, vertex: usize) usize {
	var v = vertex;
	while (parent[v] != v) { parent[v] = parent[parent[v]]; v = parent[v]; }
	return v;
}
fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @truncate((bits >> @intCast(8 * byte)) & 0xff);
}

export fn euclidean_mst(values: ?[*]const i64, length: usize,
	output: ?[*]u8, output_capacity: usize) i64 {
	const input = values orelse return -1;
	if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
	const raw_n = input[0];
	if (raw_n < 1 or raw_n > @as(i64, @intCast(MAX_POINTS))) return -1;
	const n: usize = @intCast(raw_n);
	if (length != 1 + 2 * n) return -1;
	var points: [MAX_POINTS]Point = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_POINTS;
	for (0..n) |i| {
		points[i] = .{ .x = input[1 + 2*i], .y = input[2 + 2*i] };
		if (points[i].x < -10 or points[i].x > 10 or points[i].y < -10 or points[i].y > 10) return -1;
	}
	if (!generalPosition(points, n)) return -1;
	const output_words = 2 * n - 1;
	const output_bytes = 8 * output_words;
	const out = output orelse return -2;
	if (output_capacity < output_bytes) return -2;

	var candidate = [_][MAX_POINTS]bool{[_]bool{false} ** MAX_POINTS} ** MAX_POINTS;
	if (n == 2) { candidate[0][1] = true; candidate[1][0] = true; }
	for (0..n) |a| for (a+1..n) |b| for (b+1..n) |c| {
		const turn = orientation(points[a], points[b], points[c]);
		var empty = true;
		for (0..n) |d| {
			if (d == a or d == b or d == c) continue;
			const determinant = incircle(points[a], points[b], points[c], points[d]);
			if ((determinant > 0) == (turn > 0)) { empty = false; break; }
		}
		if (empty) {
			candidate[a][b]=true; candidate[b][a]=true; candidate[a][c]=true;
			candidate[c][a]=true; candidate[b][c]=true; candidate[c][b]=true;
		}
	};
	var edges: [MAX_EDGES]Edge = undefined;
	var edge_count: usize = 0;
	for (0..n) |u| for (u+1..n) |v| {
		if (!candidate[u][v]) continue;
		const dx=points[u].x-points[v].x; const dy=points[u].y-points[v].y;
		const edge=Edge{.u=u,.v=v,.weight=dx*dx+dy*dy};
		var at=edge_count; edge_count+=1;
		while (at>0) {
			const previous=edges[at-1];
			if (previous.weight<edge.weight or (previous.weight==edge.weight and (previous.u<edge.u or (previous.u==edge.u and previous.v<=edge.v)))) break;
			edges[at]=previous; at-=1;
		}
		edges[at]=edge;
	};
	var parent=[_]usize{0} ** MAX_POINTS; var sizes=[_]usize{0} ** MAX_POINTS;
	for (0..n) |i| { parent[i]=i; sizes[i]=1; }
	var words=[_]i64{0} ** MAX_OUTPUT_WORDS;
	words[0]=@intCast(n-1);
	var selected: usize = 0;
	for (0..edge_count) |i| {
		if (selected==n-1) break;
		var left=findRoot(&parent,edges[i].u); var right=findRoot(&parent,edges[i].v);
		if (left==right) continue;
		if (sizes[left]<sizes[right]) { const temporary=left; left=right; right=temporary; }
		parent[right]=left; sizes[left]+=sizes[right];
		words[1+2*selected]=@intCast(edges[i].u); words[2+2*selected]=@intCast(edges[i].v); selected+=1;
	}
	if (selected != n-1) return -1;
	for (0..output_words) |word| storeI64Le(out,8*word,words[word]);
	return @intCast(output_bytes);
}
