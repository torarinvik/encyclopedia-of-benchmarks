export fn dbscan(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5 or length > 67) return -1;
    const n0=input[0];const eps=input[1];const minimum=input[2];
    if(n0<1 or n0>32 or eps<1 or eps>2000000 or minimum<1 or minimum>n0 or length!=3+2*@as(usize,@intCast(n0)))return -1;
    const n:usize=@intCast(n0);var x: [32]i64 = @splat(0); var y: [32]i64 = @splat(0); var labels: [32]i64 = @splat(-1); var expanded: [32]bool = @splat(false);
    for(0..n)|i|{x[i]=input[3+2*i];y[i]=input[4+2*i];if(x[i]<-1000000 or x[i]>1000000 or y[i]<-1000000 or y[i]>1000000)return -1;}
    for(0..n)|i|{for(0..i)|j|{if(x[i]==x[j] and y[i]==y[j])return -1;}}
    if(output==null or capacity<n)return -2;const e2=eps*eps;var next:i64=0;
    for(0..n)|i|{if(labels[i]>=0)continue;var count:usize=0;for(0..n)|j|{const dx=x[i]-x[j];const dy=y[i]-y[j];if(dx*dx+dy*dy<=e2)count+=1;}if(count<@as(usize,@intCast(minimum)))continue;
        const cluster=next;next+=1;labels[i]=cluster;var queue: [32]usize = @splat(0); var queued: [32]bool = @splat(false);var head:usize=0;var tail:usize=0;
        for(0..n)|j|{const dx=x[i]-x[j];const dy=y[i]-y[j];if(dx*dx+dy*dy<=e2){queue[tail]=j;tail+=1;queued[j]=true;}}
        while(head<tail){const q=queue[head];head+=1;if(labels[q]>=0 and labels[q]!=cluster)continue;labels[q]=cluster;if(expanded[q])continue;expanded[q]=true;var nc:usize=0;for(0..n)|j|{const dx=x[q]-x[j];const dy=y[q]-y[j];if(dx*dx+dy*dy<=e2)nc+=1;}if(nc>=@as(usize,@intCast(minimum))){for(0..n)|j|{const dx=x[q]-x[j];const dy=y[q]-y[j];if(dx*dx+dy*dy<=e2 and labels[j]<0 and !queued[j]){queue[tail]=j;tail+=1;queued[j]=true;}}}}
    }
    for(0..n)|i|{output[i]=@intCast(if(labels[i]<0)0 else labels[i]+1);}return @intCast(n);
}
