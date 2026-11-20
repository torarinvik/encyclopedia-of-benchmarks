const MAX_ORDER: i64 = 2;
const MAX_PARSEABLE_INPUT: usize = 2;

#[derive(Clone, Copy, Default)]
struct Frame { symbol: u8, level: u8 }

fn push(stack: &mut [Frame; 64], top: &mut usize, symbol: u8, level: u8) {
    stack[*top] = Frame { symbol, level };
    *top += 1;
}

fn emit_curve(order: u8, output: &mut [u8]) -> usize {
    let mut stack = [Frame::default(); 64];
    let mut top = 0usize;
    let mut written = 0usize;
    push(&mut stack, &mut top, 5, 0); push(&mut stack, &mut top, 3, order);
    push(&mut stack, &mut top, 7, 0); push(&mut stack, &mut top, 2, order);
    push(&mut stack, &mut top, 9, 0); push(&mut stack, &mut top, 1, order);
    push(&mut stack, &mut top, 11, 0); push(&mut stack, &mut top, 0, order);
    while top != 0 {
        top -= 1;
        let frame = stack[top];
        if frame.symbol >= 4 { output[written] = frame.symbol - 4; written += 1; continue; }
        if frame.level == 0 { continue; }
        let child = frame.level - 1;
        match frame.symbol {
            0 => {
                push(&mut stack,&mut top,0,child); push(&mut stack,&mut top,5,0);
                push(&mut stack,&mut top,3,child); push(&mut stack,&mut top,12,0);
                push(&mut stack,&mut top,1,child); push(&mut stack,&mut top,11,0);
                push(&mut stack,&mut top,0,child);
            }
            1 => {
                push(&mut stack,&mut top,1,child); push(&mut stack,&mut top,11,0);
                push(&mut stack,&mut top,0,child); push(&mut stack,&mut top,18,0);
                push(&mut stack,&mut top,2,child); push(&mut stack,&mut top,9,0);
                push(&mut stack,&mut top,1,child);
            }
            2 => {
                push(&mut stack,&mut top,2,child); push(&mut stack,&mut top,9,0);
                push(&mut stack,&mut top,1,child); push(&mut stack,&mut top,16,0);
                push(&mut stack,&mut top,3,child); push(&mut stack,&mut top,7,0);
                push(&mut stack,&mut top,2,child);
            }
            _ => {
                push(&mut stack,&mut top,3,child); push(&mut stack,&mut top,7,0);
                push(&mut stack,&mut top,2,child); push(&mut stack,&mut top,14,0);
                push(&mut stack,&mut top,0,child); push(&mut stack,&mut top,5,0);
                push(&mut stack,&mut top,3,child);
            }
        }
    }
    written
}

#[no_mangle]
pub unsafe extern "C" fn sierpinski_curve_trace(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length == 0 || length > MAX_PARSEABLE_INPUT { return -1; }
    if length != 1 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_ptr, length) };
    if input[0] < 0 || input[0] > MAX_ORDER { return -1; }
    let order = input[0] as usize;
    let mut required = 4usize;
    for _ in 0..order { required *= 4; }
    if output_ptr.is_null() || capacity < required { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output_ptr, required) };
    emit_curve(order as u8, output) as i64
}
