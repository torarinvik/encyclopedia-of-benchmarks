module fast_inverse_sqrt_java_check;
extern fn double sqrt(double value);

fn long fast_inverse_sqrt_java_check(long* input, usz length) @export("fast_inverse_sqrt_java_check") {
    if (input == null || length != 2) return -1;
    if (input[0] == 0) {
        if (input[1] < 0x00800000 || input[1] > 0x7f7fffff) return -1;
        uint bits=(uint)input[1]; float number=bitcast(bits,float); float x=number; float xhalf=0.5f*x;
        long seed=(long)bits; seed=0x5f3759df-(seed>>1); uint seed_bits=(uint)seed; x=bitcast(seed_bits,float);
        x=x*(1.5f-xhalf*x*x);
        float expected=1.0f/(float)sqrt((double)number);
        return x==expected ? 1 : 0;
    }
    if (input[0] == 1) {
        if (input[1] < 0x0010000000000000 || input[1] > 0x7fefffffffffffff) return -1;
        ulong bits=(ulong)input[1]; double number=bitcast(bits,double); double x=number; double xhalf=0.5*x;
        long seed=(long)bits; seed=0x5fe6ec85e7de30da-(seed>>1); ulong seed_bits=(ulong)seed; x=bitcast(seed_bits,double);
        for (int iteration=0;iteration<4;iteration++) x=x*(1.5-xhalf*x*x);
        x*=number;
        return x==1.0/sqrt(number) ? 1 : 0;
    }
    return -1;
}
