CC=gcc
FC=gfortran
CFLAGS=-fopenmp -foffload=nvptx-none -D_OFFLOAD
CINCL=-I${CUDA_HOME}/include
FFLAGS=-fopenmp -foffload=nvptx-none
LINKFLAGS=-fopenmp -foffload=nvptx-none

all: minicode.x sync_behaviour.x

test: test_minicode test_sync

test_minicode: sync_behaviour.x
	rm -rf results/minicode_results.txt
	nvidia-smi >> results/minicode_results.txt
	echo "" >> results/minicode_results.txt
	echo "Test with 4 walkers, 100 of orbitals, and 1000 of basis function" >> results/minicode_results.txt
	echo "" >> results/minicode_results.txt
	echo 4 100 1000 | ./minicode.x >> results/minicode_results.txt ; \

test_sync: sync_behaviour.x
	rm -rf results/sync_results.txt
	nvidia-smi >> results/sync_results.txt
	echo "" >> results/sync_results.txt
	echo "# Dimension(small) \t Dimension(big) \t Time(small) \t Time(big)" >> results/sync_results.txt
	for big in 4000 6000 8000 10000 12000 ; do \
	  echo 2500 $${big} ; \
	  echo 2500 $${big} | ./sync_behaviour.x | awk -f process.awk >> results/sync_results.txt ; \
	done
	for small in 3500 4500 5500 6500 ; do \
	  echo $${small} 10000 ; \
	  echo $${small} 10000 | ./sync_behaviour.x | awk -f process.awk >> results/sync_results.txt ; \
	done

minicode.x: minicode.o fortran.o
	${FC} ${LINKFLAGS} -L${CUDA_HOME}/lib64 -lcublas -lcudart $^ -o $@

sync_behaviour.x: sync_behaviour.o fortran.o
	${FC} ${LINKFLAGS} -L${CUDA_HOME}/lib64 -lcublas -lcudart $^ -o $@

%.o: %.f90
	${FC} ${FFLAGS} -c $<

fortran.o: fortran.c
	${CC} ${CFLAGS} ${CINCL} -c $<

clean:
	rm *.o *.x

