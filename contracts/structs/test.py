import random
from numba import njit
import numpy


@njit(parallel=True)
def run_experiment():
    total_experiments = 10_000_000
    subset =numpy.random.choice(numpy.arange(1, 100), 24, replace=False)
    g = numpy.zeros(total_experiments)
    for i in range(total_experiments):
        random_numbers = numpy.random.choice(numpy.arange(1, 100), 63, replace=False)
        valid = True
        for j in subset:
            if j not in random_numbers:
                valid = False
                break
        if valid:
            g[i] = 1
            print("OK")

    # count non-zero elements
    success_count = numpy.count_nonzero(g)
    print("success count: ", success_count)
    print("total experiments: ", total_experiments)
    probability = success_count / total_experiments
    return probability

if __name__ == "__main__":
    probability = run_experiment()
    print(f"Probability of the subset condition: {probability}")