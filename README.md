# OpenMP-minicode

Small minicode to exploit OpenMP threading and executing CUDA kernels. It consists of two executables.

## Sync Behaviour

First one is `sync_behaviour.x`, showing the cudasync behaviour. It was not clear whether it synchronizes GPU jobs per process or thread. This minicode creates two OpenMP threads each one executing one Dgemm on the GPU. However, one Dgemm is small whereas the other one is big. Then the time spent on cudasync is measured on both threads. As it can be seen in [sync_results_example.txt](results/sync_results_example.txt) both take different times showing that the synchronization works per thread.

## Minicode

This small app shows how it can be used in QMC code. One can run multiple walkers as separate OpenMP threads then all walkers will be offloaded at once, lowering the transfer overhead. After that, each walker will execute its own Dgemv kernel and sync itself. One specifies the number of walkers, orbitals and basis and executes the code.

```
export NW=4
export NORB=100
export NBAS=1000
echo $NW $NORB $NBAS | ./minicode.x
```

## Compilation

To compile the code one has to have GNU compiler collection capable of offloading to Nvidia GPUs and Cuda libraries specified in CUDA_HOME environment variable. To run the test execute `make test`
