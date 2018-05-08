# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3

MY_PL="${PV##*_p}"
if [ ${MY_PL} -ge 9999 ] ; then
	MY_P="${P}"
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	if [ ${MY_PL} -gt 9999 ] ; then
		MYCY=${MY_PL%????}
		MYCM=${MY_PL#????} && MYCM="${MY_PL%??}"
		MYCD=${MY_PL#??????}
		EGIT_COMMIT_DATE="${MYCY}-${MYCM}-${MYCD}"
	fi
else
	MY_PV="${PV/_p/-patch}"
	MY_P="${PN}-${MY_PV}"
	SRC_URI="http://github.com/${PN}/${PN}/archive/${MY_PV}.tar.gz"
fi

DESCRIPTION="Kokkos C++ Performance Portability Programming EcoSystem: The Programming Model - Parallel Execution and Memory Abstraction."
HOMEPAGE="https://github.com/kokkos/kokkos"
SRC_URI=""


LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="dev-cpp/gtest"
RDEPEND="${DEPEND}"

BUILD_DIR="${S}_build"

src_prepare() {

	mkdir "${BUILD_DIR}"
	default
}

src_configure() {
	pushd "${BUILD_DIR}" > /dev/null
	bash "${S}/generate_makefile.bash" --prefix="${EPREFIX}/usr"
	popd > /dev/null
}

src_test() {
	pushd "${BUILD_DIR}" > /dev/null
	emake build-test
	emake test
	popd > /dev/null
}

src_compile() {
	pushd "${BUILD_DIR}" > /dev/null
	emake kokkoslib
	popd > /dev/null
}

src_install() {
	DOCS=( CHANGELOG.md Copyright.txt LICENSE README master_history.txt )
	dodoc

	# Install sources
	insinto "${EPREFIX}/usr/src/${CATEGORY}/${PN}"
	insopts ""
	doins -r "${S}" 

	# Fix up install paths before running make install
	pushd "${S}" > /dev/null
		mkdir -p "${ED}/usr/share/${P}"
		sed -e 's:$(PREFIX)/\(lib\|include\):&/'"${P}"':g' -i core/src/Makefile core/src/Makefile.generate_build_files || die
		sed -e 's:$(PREFIX):$(DESTDIR)/&:g' \
			-e 's:.*cp.*KOKKOS.*MAKEFILE.*$(PREFIX).*:&/share/'"${P}"':' \
			-e 's:$(PREFIX)/bin:$(PREFIX)/share/'"${P}"':' \
			-i core/src/Makefile || die
	popd > /dev/null

	# Install libs, headers, and build files.
	pushd "${BUILD_DIR}" > /dev/null
		emake install PREFIX="${EPREFIX}/usr" DESTDIR="${D%/}"
		sed -e 's:'"${S}"'/bin/nvcc_wrapper:'"${EPREFIX}"'/$(PREFIX)/share/'"${P}"'/nvcc_wrapper:' -i "${ED}/usr/share/${P}"/{Makefile.kokkos,kokkos_generated_settings.cmake} || die
	popd > /dev/null
}

