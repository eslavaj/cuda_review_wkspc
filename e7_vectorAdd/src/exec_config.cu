//============================================================================
// Name        : parallelization1.cpp
// Author      : 
// Version     :
// Copyright   : Your copyright notice
// Description : Hello World in C++, Ansi-style
//============================================================================

#include <stdio.h>
#include <assert.h>

void initWith(float num, float *a, int N)
{
  for(int i = 0; i < N; ++i)
  {
    a[i] = num;
  }
}

__global__ void addVectorsInto(float *result, float *a, float *b, int N)
{
  /*
  for(int i = 0; i < N; ++i)
  {
    result[i] = a[i] + b[i];
  }
  */

	size_t stride_s = gridDim.x * blockDim.x;

	for(int i = threadIdx.x + blockDim.x*blockIdx.x; i<N; i = i + stride_s)
	{
		result[i] = a[i] + b[i];
	}


}

void checkElementsAre(float target, float *array, int N)
{
  for(int i = 0; i < N; i++)
  {
    if(array[i] != target)
    {
      printf("FAIL: array[%d] - %0.0f does not equal %0.0f\n", i, array[i], target);
      exit(1);
    }
  }
  printf("SUCCESS! All values added correctly.\n");
}


cudaError_t cudaRunCheck(cudaError_t result)
{
	if(result != cudaSuccess)
	{
		printf("Error: %s\n", cudaGetErrorString(result));
		assert(result == cudaSuccess);
	}

	return result;

}


int main()
{
  const int N = 2<<20;
  size_t size = N * sizeof(float);

  float *a;
  float *b;
  float *c;
/*
  a = (float *)malloc(size);
  b = (float *)malloc(size);
  c = (float *)malloc(size);
*/

  cudaRunCheck(cudaMallocManaged(&a, size));
  cudaRunCheck(cudaMallocManaged(&b, size));
  cudaRunCheck(cudaMallocManaged(&c, size));

  initWith(3, a, N);
  initWith(4, b, N);
  initWith(0, c, N);

  size_t nbrThreadsBlock = 1024;
  size_t nbrBlocks = (N + nbrThreadsBlock -1)/nbrThreadsBlock;

  addVectorsInto<<<nbrBlocks, nbrThreadsBlock>>>(c, a, b, N);

  cudaDeviceSynchronize();

  cudaError_t kernelRun_err = cudaGetLastError();

  if(kernelRun_err != cudaSuccess)
  {
	  printf("Error kernel launch: %s", cudaGetErrorString(kernelRun_err));
  }


  checkElementsAre(7, c, N);

  cudaFree(a);
  cudaFree(b);
  cudaFree(c);
}
