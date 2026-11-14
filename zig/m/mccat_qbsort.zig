const std = @import("std");
const MAX_ITEMS: usize = 32;
fn bubble(a: *[MAX_ITEMS]i32, n: usize) void { var end=n; while(end>1):(end-=1){var i:usize=0;while(i+1<end):(i+=1){if(a[i+1]<a[i]){std.mem.swap(i32,&a[i],&a[i+1]);}}} }
const Node = struct { value: i32, next: ?*Node };
fn freeNodes(head: ?*Node) void {
    var cursor = head;
    while (cursor) |node| { cursor = node.next; std.heap.page_allocator.destroy(node); }
}
fn prepend(head: ?*Node, value: i32) !*Node {
    const node = try std.heap.page_allocator.create(Node);
    node.* = .{ .value = value, .next = head };
    return node;
}
fn quick(head: ?*const Node) anyerror!?*Node {
    const first = head orelse return null;
    var lower: ?*Node = null;
    var upper: ?*Node = null;
    defer freeNodes(lower);
    defer freeNodes(upper);
    var cursor: ?*const Node = first.next;
    while (cursor) |node| {
        if (node.value < first.value) lower = try prepend(lower, node.value)
        else upper = try prepend(upper, node.value);
        cursor = node.next;
    }
    const sorted_upper = try quick(upper);
    errdefer freeNodes(sorted_upper);
    const sorted_lower = try quick(lower);
    errdefer freeNodes(sorted_lower);
    const pivot = try prepend(sorted_upper, first.value);
    if (sorted_lower) |start| {
        var tail = start;
        while (tail.next) |next| tail = next;
        tail.next = pivot;
        return start;
    }
    return pivot;
}
export fn mccat_qbsort(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<3 or length>2+MAX_ITEMS)return -1;const input=input_opt.?;const mode=input[0];const cv=input[1];
    if((mode!=0 and mode!=1) or cv<1 or cv>MAX_ITEMS)return -1;const n:usize=@intCast(cv);if(length!=n+2)return -1;
    var a=[_]i32{0}**MAX_ITEMS;for(0..n)|i|{if(input[i+2]<std.math.minInt(i32) or input[i+2]>std.math.maxInt(i32))return -1;a[i]=@intCast(input[i+2]);}
    for(0..1000)|_|{
        for(0..n)|i|{a[i]=@intCast(input[i+2]);}
        if(mode==0) bubble(&a,n) else {
            var items: ?*Node = null;
            var i = n;
            while (i > 0) {
                i -= 1;
                items = prepend(items, a[i]) catch { freeNodes(items); return -1; };
            }
            const sorted = quick(items) catch { freeNodes(items); return -1; };
            freeNodes(items);
            var current = sorted;
            i = 0;
            while (current) |node| { a[i] = node.value; i += 1; current = node.next; }
            freeNodes(sorted);
        }
    }
    const need=4*n;const output=output_opt orelse return -2;if(capacity<need)return -2;for(0..n)|i|{const bits:u32=@bitCast(a[i]);for(0..4)|b|output[4*i+b]=@truncate(bits>>@as(u5,@intCast(8*b)));}return @intCast(need);
}
