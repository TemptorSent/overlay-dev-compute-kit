# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

PYTHON_COMPAT=( python2_7 )

FORTRAN_STANDARD="77 90"

inherit cuda eutils flag-o-matic fortran-2 multilib toolchain-funcs versionator python-any-r1

DESCRIPTION="Matrix Algebra on GPU and Multicore Architectures"
HOMEPAGE="http://icl.cs.utk.edu/magma/"
SRC_URI="http://icl.cs.utk.edu/projectsfiles/${PN}/downloads/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~amd64-linux"

NVIDIA_CUDA_CARDS=" nvidia_cuda_fermi nvidia_cuda_kepler nvidia_cuda_maxwell nvidia_cuda_pascal nvidia_cuda_volta"

IUSE="${NVIDIA_CUDA_CARDS} static-libs test"

REQUIRED_USE="?? ( nvidia_cuda_fermi nvidia_cuda_kepler nvidia_cuda_maxwell nvidia_cuda_pascal nvidia_cuda_volta )"

RDEPEND="
	sci-util/openblas
	dev-util/nvidia-cuda-toolkit"
#	virtual/cblas
#	virtual/lapack"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? ( ${PYTHON_DEPS} )"

# We have to have write acccess /dev/nvidia0 and /dev/nvidiactl and the portage
# user is (usually) not in the video group
RESTRICT="userpriv"

pkg_setup() {
	fortran-2_pkg_setup
	use test && python-any-r1_pkg_setup
}

src_prepare() {
	# distributed pc file not so useful so replace it
	cat <<-EOF > ${PN}.pc
		prefix=${EPREFIX}/usr
		libdir=\${prefix}/$(get_libdir)
		includedir=\${prefix}/include/${PN}
		Name: ${PN}
		Description: ${DESCRIPTION}
		Version: ${PV}
		URL: ${HOMEPAGE}
		Libs: -L\${libdir} -lmagma
		Libs.private: -lm -lpthread -ldl -lcublas -lcudart
		Cflags: -I\${includedir}
		Requires: cblas lapack
	EOF

	if [[ $(tc-getCC) =~ gcc ]]; then
		local eopenmp=-fopenmp
	elif [[ $(tc-getCC) =~ icc ]]; then
		local eopenmp=-openmp
	else
		elog "Cannot detect compiler type so not setting openmp support"
	fi
	#append-flags -fPIC ${eopenmp}
	#append-ldflags -Wl,-soname,lib${PN}.so.1.4 ${eopenmp}

	cuda_src_prepare
}

src_configure() {


	# GPU_TARGET contains one or more of Fermi, Kepler, Maxwell, Pascal, Volta
	# to specify for which GPUs you want to compile MAGMA:
	#     Fermi   - NVIDIA compute capability 2.x cards
	#     Kepler  - NVIDIA compute capability 3.x cards
	#     Maxwell - NVIDIA compute capability 5.x cards
	#     Pascal  - NVIDIA compute capability 6.x cards
	#     Volta   - NVIDIA compute capability 7.x cards
	local GPU_TARGET=""

	use nvidia_cuda_fermi && GPU_TARGET=+" Fermi"
	use nvidia_cuda_kepler && GPU_TARGET=+" Kepler"
	use nvidia_cuda_maxwell && GPU_TARGET=+" Maxwell"
	use nvidia_cuda_pascal && GPU_TARGET=+" Pascal"
	use nvidia_cuda_volta && GPU_TARGET=+" Volta"

	CUDADIR="${EPREFIX}/opt/cuda"
	OPENBLASDIR="${EPREFIX}/opt/OpenBLAS"
	export GPU_TARGET CUDADIR OPENBLASDIR
	cat make.inc-examples/make.inc.openblas \
		| sed \
			-e 's:^#?GPU_TARGET .*=.*:GPU_TARGET = '"${GPU_TARGET}"':' \
			-e 's:^#?CUDADIR .*=.*:CUDADIR = '"${CUDADIR}"':' \
			-e 's:^#?OPENBLASDIR .*=.*:OPENBLASDIR = '"${OPENBLASDIR}"':' \
			-e 's:^#?CC .*=.*:CC = '"$(tc-getCC)"':' \
			-e 's:^#?CXX .*=.*:CXX = '"$(tc-getCXX)"':' \
			-e 's:^#?NVCC .*=.*:NVCC = '"${NVCC}"':' \
			-e 's:^#?FORT .*=.*:FORT = '"$(tc-getFC)"':' \
			-e 's:^#?ARCH .*=.*:ARCH = '"$(tc-getAR)"':' \
			-e 's:^#?RANLIB .*=.*:RANLIB = '"$(tc-getRANLIB)"':' \
		> make.inc
#	cat <<-EOF > make.inc
#		ARCH = $(tc-getAR)
#		ARCHFLAGS = cr
#		RANLIB = $(tc-getRANLIB)
#		NVCC = nvcc
#		CC = $(tc-getCC)
#		CXX = $(tc-getCXX)
#		FORT = $(tc-getFC)
#		INC = -I"${EPREFIX}/opt/cuda/include" -DADD_ -DCUBLAS_GFORTRAN
#		OPTS = ${CFLAGS} -fPIC
#		FOPTS = ${FFLAGS} -fPIC -x f95-cpp-input
#		F77OPTS = ${FFLAGS} -fPIC
#		NVOPTS = -DADD_ -DUNIX ${NVCCFLAGS}
#		LDOPTS = ${LDFLAGS}
#		LOADER = $(tc-getFC)
#		LIBBLAS = $($(tc-getPKG_CONFIG) --libs cblas)
#		LIBLAPACK = $($(tc-getPKG_CONFIG) --libs lapack)
#		CUDADIR = ${EPREFIX}/opt/cuda
#		LIBCUDA = -L\$(CUDADIR)/$(get_libdir) -lcublas -lcudart
#		LIB = -pthread -lm -ldl \$(LIBCUDA) \$(LIBBLAS) \$(LIBLAPACK) -lstdc++
#		GPU_TARGET =${GPU_TARGET}
#	EOF
}

src_compile() {
	emake lib
	emake shared
#	mv lib/lib${PN}.so{,.1.4} || die
#	ln -sf lib${PN}.so.1.4 lib/lib${PN}.so.1 || die
#	ln -sf lib${PN}.so.1.4 lib/lib${PN}.so || die
}

src_test() {
	emake test lapacktest
	cd testing/lin || die
	# we need to access this while running the tests
	addwrite /dev/nvidiactl
	addwrite /dev/nvidia0
	LD_LIBRARY_PATH="${S}"/lib ${EPYTHON} lapack_testing.py || die
}

src_install() {
	dolib.so lib/lib*$(get_libname)*
	use static-libs && dolib.a lib/lib*.a
	insinto /usr/include/${PN}
	doins include/*.h
	insinto /usr/$(get_libdir)/pkgconfig
	doins ${PN}.pc
	dodoc README ReleaseNotes
}
