# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit fortran-2

MY_PN="OpenBLAS"
MY_P="${MY_PN}-${PV}"
DESCRIPTION="An optimized BLAS library based on GotoBLAS2 1.13 BSD version."
HOMEPAGE="https://www.openblas.net"
SRC_URI="https://github.com/xianyi/OpenBLAS/archive/v${PV}.tar.gz"

LICENSE="BSD-3"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

src_test() {
	# Run all tests
	emake tests lapack-test blas-test
}

src_install() {
	default
	insinto /etc/env.d/blas/$(get_libdir)
	newins "${FILESDIR}/openblas.eselect" "openblas"
}
