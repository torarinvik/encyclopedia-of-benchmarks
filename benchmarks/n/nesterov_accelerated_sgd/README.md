# Nesterov accelerated SGD

This benchmark follows the pinned Python optimizer's stateful update. For each step, it saves the previous velocity, computes `velocity = momentum * velocity - learning_rate * gradient`, then returns updated parameters `params - momentum * previous_velocity + (1 + momentum) * velocity`. Velocity starts at zero for each invocation and persists across the bounded sequence of supplied gradients.

Input is `[width, step_count, learning_rate_milli, momentum_milli, initial_parameters_milli..., gradients_by_step_milli...]`. Width and step count are 1–8; learning rate and momentum are scaled thousandths in [0,1]; parameter and gradient components are scaled thousandths in [-10,10]. Output contains the final parameters as little-endian binary64 values. The runtime oracle is `nesterov_accelerated_sgd_oracle.py`.
