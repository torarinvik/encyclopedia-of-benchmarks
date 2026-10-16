module is_isomorphic

const max_codepoints = 8
const max_input_length = 2 + 2 * max_codepoints + 2

@[export: 'is_isomorphic']
pub fn is_isomorphic(input &i64, length usize) i64 {
    if length < 2 || length > max_input_length { return -1 }
    unsafe {
        source_length := input[0]
        target_length := input[1]
        if source_length < 0 || source_length > max_codepoints || target_length < 0 || target_length > max_codepoints {
            return -1
        }
        source_count := int(source_length)
        target_count := int(target_length)
        if int(length) != 2 + source_count + target_count { return -1 }
        for index in 2 .. int(length) {
            if input[index] < 0 || input[index] > 127 { return -1 }
        }
        if source_count != target_count { return 0 }

        mut source_to_target := [128]i64{init: -1}
        mut target_to_source := [128]i64{init: -1}
        for index in 0 .. source_count {
            source := int(input[2 + index])
            target := int(input[2 + source_count + index])
            if (source_to_target[source] != -1 && source_to_target[source] != target) ||
                (target_to_source[target] != -1 && target_to_source[target] != source) { return 0 }
            source_to_target[source] = target
            target_to_source[target] = source
        }
        return 1
    }
}
