module mini_batch_gradient_descent;

const usz MAX_SAMPLES=8;
const usz MAX_FEATURES=3;
const usz MAX_INPUT=101;

fn bool finite_value(double x) { return x==x && x<1e300 && x> -1e300; }

fn long mini_batch_gradient_descent(double* input, usz input_length,
                                   double* output, usz output_capacity) @export("mini_batch_gradient_descent") {
    if(input==null || input_length<5 || input_length>MAX_INPUT) return -1L;
    for(usz i=0;i<input_length;i++) if(!finite_value(input[i])) return -1L;
    if(input[0]<1.0 || input[0]>8.0 || input[1]<1.0 || input[1]>3.0) return -1L;
    usz samples=(usz)(long)input[0], features=(usz)(long)input[1];
    if((double)(long)input[0]!=input[0] || (double)(long)input[1]!=input[1]) return -1L;
    if(input[2]<1.0 || input[2]>(double)samples || input[3]<0.0 || input[3]>8.0) return -1L;
    if((double)(long)input[2]!=input[2] || (double)(long)input[3]!=input[3]) return -1L;
    usz batch_size=(usz)(long)input[2], epochs=(usz)(long)input[3];
    double learning_rate=input[4];
    if(learning_rate<0.0 || learning_rate>0.25) return -1L;
    usz matrix_start=5, matrix_end=matrix_start+samples*features, targets_end=matrix_end+samples;
    if(input_length!=targets_end+epochs*samples) return -1L;
    double[MAX_SAMPLES*MAX_FEATURES] matrix=zeroed;
    double[MAX_SAMPLES] targets=zeroed;
    for(usz i=0;i<samples*features;i++) {
        double x=input[matrix_start+i]; if(x< -10.0 || x>10.0) return -1L;
        matrix[i]=x;
    }
    for(usz i=0;i<samples;i++) {
        double y=input[matrix_end+i]; if(y< -100.0 || y>100.0) return -1L;
        targets[i]=y;
    }
    usz[64] orders=zeroed;
    for(usz epoch=0;epoch<epochs;epoch++) {
        bool[MAX_SAMPLES] seen=zeroed;
        for(usz pos=0;pos<samples;pos++) {
            double value=input[targets_end+epoch*samples+pos];
            if(value<0.0 || value>=(double)samples || (double)(long)value!=value) return -1L;
            usz index=(usz)(long)value;
            if(seen[index]) return -1L;
            seen[index]=true;
            orders[epoch*samples+pos]=index;
        }
    }
    double[MAX_FEATURES] weights=zeroed;
    double bias=0.0;
    for(usz epoch=0;epoch<epochs;epoch++) {
        for(usz start=0;start<samples;start+=batch_size) {
            usz length=samples-start; if(length>batch_size) length=batch_size;
            double[MAX_SAMPLES] errors=zeroed;
            for(usz pos=0;pos<length;pos++) {
                usz sample=orders[epoch*samples+start+pos];
                double prediction=0.0;
                for(usz feature=0;feature<features;feature++) {
                    double product=matrix[sample*features+feature]*weights[feature];
                    if(!finite_value(product)) return -1L;
                    prediction+=product; if(!finite_value(prediction)) return -1L;
                }
                prediction+=bias; if(!finite_value(prediction)) return -1L;
                errors[pos]=prediction-targets[sample]; if(!finite_value(errors[pos])) return -1L;
            }
            for(usz feature=0;feature<features;feature++) {
                double gradient=0.0;
                for(usz pos=0;pos<length;pos++) {
                    usz sample=orders[epoch*samples+start+pos];
                    double product=matrix[sample*features+feature]*errors[pos];
                    if(!finite_value(product)) return -1L;
                    gradient+=product; if(!finite_value(gradient)) return -1L;
                }
                double update=(learning_rate*gradient)/(double)length;
                if(!finite_value(update)) return -1L;
                weights[feature]-=update; if(!finite_value(weights[feature])) return -1L;
            }
            double error_sum=0.0;
            for(usz pos=0;pos<length;pos++) {
                error_sum+=errors[pos]; if(!finite_value(error_sum)) return -1L;
            }
            double mean_error=error_sum/(double)length;
            if(!finite_value(mean_error)) return -1L;
            double bias_update=learning_rate*mean_error;
            if(!finite_value(bias_update)) return -1L;
            bias-=bias_update; if(!finite_value(bias)) return -1L;
        }
    }
    double[MAX_FEATURES+1] staged=zeroed;
    for(usz i=0;i<features;i++) staged[i]=weights[i];
    staged[features]=bias;
    usz result_length=features+1;
    if(output==null || output_capacity<result_length) return -2L;
    for(usz i=0;i<result_length;i++) output[i]=staged[i];
    return (long)result_length;
}
