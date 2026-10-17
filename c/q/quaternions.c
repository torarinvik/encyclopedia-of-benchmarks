#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_INPUT_LENGTH 10
#define MAX_COMPONENT 1.0f

static int valid_finite_inputs(const double *input, size_t length) {
    for (size_t i = 0; i < length; ++i) if (!isfinite(input[i])) return 0;
    return 1;
}

int64_t quaternions(const double *input, size_t length, double *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH || !valid_finite_inputs(input, length)) return -1;
    const double op_value = input[0];
    if (op_value != 0.0 && op_value != 1.0 && op_value != 2.0) return -1;
    const int operation = (int)op_value;
    const size_t expected_length = operation == 0 ? 4 : operation == 1 ? 5 : 9;
    const size_t result_length = operation == 1 ? 3 : 4;
    if (length != expected_length) return -1;

    float values[8];
    if (operation == 0) {
        for (size_t i = 1; i < 4; ++i) {
            if (input[i] < -3.0 || input[i] > 3.0) return -1;
            values[i - 1] = (float)input[i];
        }
    } else if (operation == 1) {
        for (size_t i = 1; i < 5; ++i) {
            values[i - 1] = (float)input[i];
            if (values[i - 1] < -MAX_COMPONENT || values[i - 1] > MAX_COMPONENT) return -1;
        }
        const float w=values[0], q1=values[1], q2=values[2], q3=values[3];
        float norm = w*w; norm = norm + q1*q1; norm = norm + q2*q2; norm = norm + q3*q3;
        if (fabsf(norm - 1.0f) > 1e-6f) return -1;
        float pitch_arg = w*q2 + q1*q3; pitch_arg = 2.0f*pitch_arg;
        if (pitch_arg < -1.0f || pitch_arg > 1.0f) return -1;
    } else {
        for (size_t i = 1; i < 9; ++i) {
            if (input[i] < -1.0 || input[i] > 1.0) return -1;
            values[i - 1] = (float)input[i];
        }
    }
    if (output == NULL || output_capacity < result_length) return -2;

    float result[4];
    if (operation == 0) {
        const float yaw=values[0], pitch=values[1], roll=values[2];
        const float cy=cosf(yaw*0.5f), sy=sinf(yaw*0.5f);
        const float cp=cosf(pitch*0.5f), sp=sinf(pitch*0.5f);
        const float cr=cosf(roll*0.5f), sr=sinf(roll*0.5f);
        result[0]=(cr*cp)*cy+(sr*sp)*sy;
        result[1]=(sr*cp)*cy-(cr*sp)*sy;
        result[2]=(cr*sp)*cy+(sr*cp)*sy;
        result[3]=(cr*cp)*sy-(sr*sp)*cy;
    } else if (operation == 1) {
        const float w=values[0], q1=values[1], q2=values[2], q3=values[3];
        const float roll_y=2.0f*(w*q1+q2*q3);
        const float roll_x=1.0f-2.0f*(q1*q1+q2*q2);
        const float pitch=asinf(2.0f*(w*q2+q1*q3));
        const float yaw_y=2.0f*(w*q3+q1*q2);
        const float yaw_x=1.0f-2.0f*(q2*q2+q3*q3);
        result[0]=atan2f(roll_y,roll_x); result[1]=pitch; result[2]=atan2f(yaw_y,yaw_x);
    } else {
        const float aw=values[0],a1=values[1],a2=values[2],a3=values[3];
        const float bw=values[4],b1=values[5],b2=values[6],b3=values[7];
        result[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;
        result[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;
        result[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;
        result[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw;
    }
    for (size_t i = 0; i < result_length; ++i) output[i] = (double)result[i];
    return (int64_t)result_length;
}
