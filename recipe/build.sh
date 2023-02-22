set -exv

# Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
export CUDA_ARCH_LIST="sm_35,sm_50,sm_60,sm_61,sm_70,sm_75"
export CUDAARCHS="35;50;60;61;70;75"

if awk "BEGIN {exit !($cuda_compiler_version >= 11.0)}"; then
  CUDA_ARCH_LIST="$CUDA_ARCH_LIST,sm_80"
  CUDAARCHS="$CUDAARCHS;80"
fi
if awk "BEGIN {exit !($cuda_compiler_version >= 11.1)}"; then
  CUDA_ARCH_LIST="$CUDA_ARCH_LIST,sm_86"
  CUDAARCHS="$CUDAARCHS;86"
fi

# Remove CXX standard flags added by conda-forge. std=c++11 is required to
# compile some .cu files
CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

mkdir build
cd build
rm -rf *

# Upstream doesn't properly pass host compiler args to NVCC, so we have to pass
# them here with CUDA_NVCC_FLAGS.
cmake $SRC_DIR \
  -G "Unix Makefiles" \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DGPU_TARGET=$CUDA_ARCH_LIST \
  -DMAGMA_ENABLE_CUDA:BOOL=ON \
  -DUSE_FORTRAN:BOOL=OFF \
  -DCUDA_NVCC_FLAGS="" \
  ${CMAKE_ARGS}

# Explicitly name build targets to avoid building tests
cmake --build . \
    --parallel ${CPU_COUNT} \
    --target lib sparse-lib \
    --verbose

cmake --install .
