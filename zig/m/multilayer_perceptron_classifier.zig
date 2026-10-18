const std = @import("std");
const MAX_OUTPUT: usize = 26;

export fn multilayer_perceptron_classifier(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 15) return -1;
    for (0..15) |i| { if (!std.math.isFinite(values[i])) return -1; }
    if (@trunc(values[0]) != values[0] or values[0] < 1 or values[0] > 12) return -1;
    if (values[1] != 0.05 and values[1] != 0.1 and values[1] != 0.2) return -1;
    if (values[2] != 0.5 and values[2] != 0.75 and values[2] != 1.0) return -1;
    const epochs: usize = @intFromFloat(values[0]);
    for (0..8) |i| { const x=values[3+i]; if (x < -2 or x > 2 or x*4 != @trunc(x*4)) return -1; }
    var labels=[_]i32{0} ** 4;
    for (0..4) |i| { const label=values[11+i]; if (@trunc(label)!=label or label<0 or label>2) return -1; labels[i]=@intFromFloat(label); }
    var w1=[_]f64{0.30471707975443135,-1.0399841062404955,0.7504511958064572,0.9405647163912139,-1.9510351886538364,-1.302179506862318};
    var w2=[_]f64{0.12784040316728537,-0.3162425923435822,-0.016801157504288795,-0.85304392757358,0.8793979748628286,0.7777919354289483};
    var accuracies=[_]f64{0} ** 12;
    var losses=[_]f64{0} ** 12;
    var rate=values[1];
    for (0..epochs) |epoch| {
        for (0..3) |row_index| {
            const row=[_]f64{values[3+row_index*2],values[4+row_index*2],1.0};
            var z1=[_]f64{0} ** 2;
            for (0..2) |j| { var total:f64=0; for(0..3)|i| {total+=row[i]*w1[i*2+j];} z1[j]=total; }
            var hidden=[_]f64{0} ** 2;
            for(0..2)|j| {hidden[j]=if(z1[j]>0) z1[j] else 0;}
            var z2=[_]f64{0} ** 3;
            for(0..3)|k| {var total:f64=0;for(0..2)|j|{total+=hidden[j]*w2[j*3+k];}z2[k]=total;}
            var delta_out=[_]f64{0} ** 3;
            for(0..3)|k| {delta_out[k]=z2[k];if(labels[row_index]==k)delta_out[k]-=0.99;}
            var delta_hidden=[_]f64{0} ** 2;
            for(0..2)|j| {var total:f64=0;for(0..3)|k|{total+=delta_out[k]*w2[j*3+k];}delta_hidden[j]=if(z1[j]>0)total else 0;}
            var grad_w2=[_]f64{0} ** 6;
            for(0..2)|j|{for(0..3)|k|{grad_w2[j*3+k]=hidden[j]*delta_out[k];}}
            var grad_w1=[_]f64{0} ** 6;
            for(0..3)|i|{for(0..2)|j|{grad_w1[i*2+j]=row[i]*delta_hidden[j];}}
            for(0..3)|i|{for(0..2)|j|{w1[i*2+j]-=rate*grad_w1[i*2+j];}}
            for(0..2)|j|{for(0..3)|k|{w2[j*3+k]-=rate*grad_w2[j*3+k];}}
        }
        const row=[_]f64{values[9],values[10],1.0};
        var z1=[_]f64{0} ** 2;
        for(0..2)|j|{var total:f64=0;for(0..3)|i|{total+=row[i]*w1[i*2+j];}z1[j]=total;}
        var hidden=[_]f64{0} ** 2;
        for(0..2)|j|{hidden[j]=if(z1[j]>0)z1[j] else 0;}
        var predicted=[_]f64{0} ** 3;
        for(0..3)|k|{var total:f64=0;for(0..2)|j|{total+=hidden[j]*w2[j*3+k];}predicted[k]=total;}
        var best:usize=0;
        for(1..3)|k|{if(predicted[k]>predicted[best])best=k;}
        accuracies[epoch]=if(best==labels[3]) 1 else 0;
        var loss:f64=0;
        for(0..3)|k|{var difference=predicted[k];if(labels[3]==k)difference-=0.99;loss+=difference*difference;}
        losses[epoch]=loss/2.0;
        rate*=values[2];
    }
    var staged=[_]f64{0} ** MAX_OUTPUT;
    staged[0]=@floatFromInt(epochs);
    var mean:f64=0;
    for(0..epochs)|epoch|{staged[1+epoch]=accuracies[epoch];staged[1+epochs+epoch]=losses[epoch];mean+=accuracies[epoch];}
    mean/= @as(f64,@floatFromInt(epochs));
    staged[1+2*epochs]=mean;
    const output_size=2+2*epochs;
    const out=output orelse return -2;
    if(capacity<output_size)return -2;
    @memcpy(out[0..output_size],staged[0..output_size]);
    return @intCast(output_size);
}
