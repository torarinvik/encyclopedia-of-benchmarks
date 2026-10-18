const std = @import("std");
const MODE: i32 = 1;
const MAX_OUTPUT: usize = 25;

export fn perceptron_python(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 9 or input_length > 62) return -1;
    for (0..input_length) |i| { if (!std.math.isFinite(values[i])) return -1; }
    var rate: f64 = 0;
    var epochs: usize = 0;
    if (MODE == 3) {
        if (@trunc(values[0]) != values[0] or values[0] < 0 or values[0] > 12) return -1;
        epochs = @intFromFloat(values[0]); rate = values[1];
    } else {
        if (@trunc(values[1]) != values[1] or values[1] < 1 or values[1] > 12) return -1;
        epochs = @intFromFloat(values[1]); rate = values[0];
    }
    if (rate != 0.25 and rate != 0.5 and rate != 0.75 and rate != 1.0) return -1;
    if (@trunc(values[2]) != values[2] or values[2] < 2 or values[2] > 8 or @trunc(values[3]) != values[3] or values[3] < 1 or values[3] > 4) return -1;
    const samples: usize = @intFromFloat(values[2]); const features: usize = @intFromFloat(values[3]);
    const feature_start: usize = 4; const labels_start = feature_start + samples * features; const q_index = labels_start + samples;
    if (input_length <= q_index or @trunc(values[q_index]) != values[q_index] or values[q_index] < 1 or values[q_index] > 4) return -1;
    const queries: usize = @intFromFloat(values[q_index]); const query_start = q_index + 1;
    if (input_length != query_start + queries * features or input_length > 61) return -1;
    for (0..samples * features) |i| { const x=values[feature_start+i]; if (@trunc(x)!=x or x < -2 or x > 2) return -1; }
    for (0..queries * features) |i| { const x=values[query_start+i]; if (@trunc(x)!=x or x < -2 or x > 2) return -1; }
    var labels = [_]i32{0} ** 8; var classes = [_]i32{0} ** 3; var class_count: usize = 0;
    for (0..samples) |i| {
        const x=values[labels_start+i]; if (@trunc(x)!=x) return -1;
        if (MODE == 0 and x != 0 and x != 1) return -1;
        if ((MODE == 1 or MODE == 3) and x != -1 and x != 1) return -1;
        if (MODE == 2 and (x < -2 or x > 2)) return -1;
        labels[i]=@intFromFloat(x);
        if (MODE == 2) {
            var found=false; for (0..class_count) |c| { if (classes[c] == labels[i]) found=true; }
            if (!found) { if (class_count >= 3) return -1; classes[class_count]=labels[i]; class_count+=1; }
        }
    }
    if (MODE == 2) {
        if (class_count < 2) return -1;
        for (0..class_count) |i| { var j=i+1; while (j<class_count):(j+=1) { if(classes[j]<classes[i]) std.mem.swap(i32,&classes[i],&classes[j]); } }
    } else { class_count=2; }
    var weights = [_]f64{0} ** 15; var epochs_run: usize=0; var converged=false;
    if (MODE == 1) { weights[0]=-1; const seeded=[_]f64{0.8444218515250481,0.7579544029403025,0.420571580830845,0.25891675029296335}; for(0..features)|j| weights[j+1]=seeded[j]; }
    if (MODE == 0 or MODE == 1) {
        for (0..epochs) |epoch| {
            var updated=false;
            for (0..samples) |row| {
                var score: f64=0; if(MODE==0) score=weights[features]; if(MODE==1) score+=weights[0]*-1.0;
                for(0..features)|col| { const x=values[feature_start+row*features+col]; if(MODE==1) score+=weights[col+1]*x else score+=weights[col]*x; }
                const pred: i32=if(MODE==0) (if(score>=0) 1 else 0) else (if(score>=0) 1 else -1); const error=labels[row]-pred;
                if(error!=0) {
                    if(MODE==0) { for(0..features)|col| weights[col]+=rate*@as(f64,@floatFromInt(error))*values[feature_start+row*features+col]; weights[features]+=rate*@as(f64,@floatFromInt(error)); }
                    else { weights[0]+=rate*@as(f64,@floatFromInt(error))*-1.0; for(0..features)|col| weights[col+1]+=rate*@as(f64,@floatFromInt(error))*values[feature_start+row*features+col]; }
                    updated=true;
                }
            }
            epochs_run=epoch+1; if(MODE==0 and !updated) { converged=true; break; } if(MODE==1 and !updated) break;
        }
    } else if (MODE == 3) {
        for(0..epochs)|_| { var misses:usize=0; for(0..samples)|row| { var score:f64=0; for(0..features)|col| score+=weights[col]*values[feature_start+row*features+col]; score+=weights[features]; const pred:i32=if(score>=0) 1 else -1; if(pred!=labels[row]) { misses+=1; for(0..features)|col| weights[col]+=rate*@as(f64,@floatFromInt(labels[row]))*values[feature_start+row*features+col]; weights[features]+=rate*@as(f64,@floatFromInt(labels[row])); } } if(misses==0) break; }
    } else {
        const stride=features+1;
        for(0..epochs)|_| { for(0..samples)|row| {
            if(class_count==2) {
                const label:i32=if(labels[row]==classes[0]) -1 else 1; var score=weights[0]; for(0..features)|col| score+=weights[col+1]*values[feature_start+row*features+col];
                if(@as(f64,@floatFromInt(label))*score<=0) { weights[0]+=rate*@as(f64,@floatFromInt(label)); for(0..features)|col| weights[col+1]+=rate*@as(f64,@floatFromInt(label))*values[feature_start+row*features+col]; }
            } else {
                var predicted:usize=0; var best:f64=0; for(0..class_count)|c| { var score=weights[c*stride]; for(0..features)|col| score+=weights[c*stride+col+1]*values[feature_start+row*features+col]; if(c==0 or score>best) {best=score;predicted=c;} }
                var target:usize=0; for(0..class_count)|c| {if(classes[c]==labels[row]) target=c;}
                if(predicted!=target) { weights[target*stride]+=rate; weights[predicted*stride]-=rate; for(0..features)|col| {const x=values[feature_start+row*features+col];weights[target*stride+col+1]+=rate*x;weights[predicted*stride+col+1]-=rate*x;} }
            }
        } }
    }
    var staged=[_]f64{0}**MAX_OUTPUT; var out_n:usize=0;
    if(MODE==0) {staged[0]=@floatFromInt(features);for(0..features)|col|staged[1+col]=weights[col];staged[1+features]=weights[features];staged[2+features]=@floatFromInt(epochs_run);staged[3+features]=if(converged) 1 else 0;staged[4+features]=@floatFromInt(queries);out_n=5+features;}
    else if(MODE==1) {staged[0]=@floatFromInt(epochs_run);staged[1]=@floatFromInt(features+1);for(0..features+1)|j|staged[2+j]=weights[j];staged[3+features]=@floatFromInt(queries);out_n=4+features;}
    else if(MODE==3) {staged[0]=@floatFromInt(features);for(0..features)|col|staged[1+col]=weights[col];staged[1+features]=weights[features];staged[2+features]=@floatFromInt(queries);out_n=3+features;}
    else {staged[0]=@floatFromInt(class_count);for(0..class_count)|c|staged[1+c]=@floatFromInt(classes[c]);const stride=features+1;const param_n:usize=if(class_count==2) stride else class_count*stride;staged[1+class_count]=@floatFromInt(param_n);for(0..param_n)|j|staged[2+class_count+j]=weights[j];staged[2+class_count+param_n]=@floatFromInt(queries);out_n=3+class_count+param_n;}
    for(0..queries)|q| { var pred:f64=0;
        if(MODE==0) {var score=weights[features];for(0..features)|col|score+=weights[col]*values[query_start+q*features+col];if(score>=0)pred=1;}
        else if(MODE==1) {var score=weights[0]*-1.0;for(0..features)|col|score+=weights[col+1]*values[query_start+q*features+col];pred=if(score>=0) 1 else -1;}
        else if(MODE==3) {var score:f64=0;for(0..features)|col|score+=weights[col]*values[query_start+q*features+col];score+=weights[features];pred=if(score>=0) 1 else -1;}
        else if(class_count==2) {var score=weights[0];for(0..features)|col|score+=weights[col+1]*values[query_start+q*features+col];pred=@floatFromInt(if(score>=0) classes[1] else classes[0]);}
        else {var best:f64=0;var chosen:usize=0;const stride=features+1;for(0..class_count)|c|{var score=weights[c*stride];for(0..features)|col|score+=weights[c*stride+col+1]*values[query_start+q*features+col];if(c==0 or score>best){best=score;chosen=c;}}pred=@floatFromInt(classes[chosen]);}
        staged[out_n]=pred;out_n+=1;
    }
    const out=output orelse return -2; if(capacity<out_n)return -2; @memcpy(out[0..out_n],staged[0..out_n]);return @intCast(out_n);
}
