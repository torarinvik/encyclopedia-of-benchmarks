package gradient_boosting_regressor
import "core:c"
INVALID_RESULT :: -1.0e300
MAX_SAMPLES :: 16
@(export)
gradient_boosting_regressor :: proc "c" (v: [^]i64, length: c.size_t) -> f64 {
    if v == nil || length < 8 || length > 36 do return INVALID_RESULT
    n64, rounds, rate_i, query := v[0],v[1],v[2],v[3]
    if n64 < 2 || n64 > MAX_SAMPLES || rounds < 1 || rounds > 12 || rate_i < 1 || rate_i > 1000000 || length != c.size_t(4+2*n64) do return INVALID_RESULT
    n := int(n64)
    x: [MAX_SAMPLES]f64
    y: [MAX_SAMPLES]f64
    pred: [MAX_SAMPLES]f64
    residual: [MAX_SAMPLES]f64
    for i in 0..<n {
        xi,yi := v[4+i],v[4+n+i]
        if xi < -1000 || xi > 1000 || yi < -1000000 || yi > 1000000 || (i>0 && v[3+i]>=xi) do return INVALID_RESULT
        x[i]=f64(xi);y[i]=f64(yi)/1000.0
    }
    if query < -1000 || query > 1000 do return INVALID_RESULT
    mean: f64=0
    for i in 0..<n { mean += y[i] }
    mean /= f64(n)
    for i in 0..<n { pred[i]=mean }
    qpred:=mean;rate:=f64(rate_i)/1000000.0
    for _ in 0..<int(rounds) {
        sum: f64=0
        for i in 0..<n { residual[i]=y[i]-pred[i];sum+=residual[i] }
        constant:=true
        for i in 1..<n { if residual[i]!=residual[0] {constant=false} }
        best:=1.0e300;split:=n;left:f64=0;right:f64=0
        if !constant {
            for s in 0..<n-1 {
                nl:=s+1;nr:=n-nl;sl:f64=0;sr:f64=0
                for i in 0..<nl {sl+=residual[i]};for i in nl..<n {sr+=residual[i]}
                lm:=sl/f64(nl);rm:=sr/f64(nr);err:f64=0
                for i in 0..<nl {d:=residual[i]-lm;err+=d*d};for i in nl..<n {d:=residual[i]-rm;err+=d*d}
                if err<best {best=err;split=s;left=lm;right=rm}
            }
        }
        if split==n {leaf:=sum/f64(n);for i in 0..<n {pred[i]+=rate*leaf};qpred+=rate*leaf}
        else {t:=(x[split]+x[split+1])/2.0;for i in 0..<n {if x[i]<=t {pred[i]+=rate*left}else{pred[i]+=rate*right}};if f64(query)<=t {qpred+=rate*left}else{qpred+=rate*right}}
    }
    return qpred
}
