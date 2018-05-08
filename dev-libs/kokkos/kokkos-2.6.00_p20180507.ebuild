# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3
MY_PN="${PN%%-*}"
MY_PL="${PV##*_p}"
if [ ${MY_PL} -ge 9999 ] ; then
	EGIT_REPO_URI="https://github.com/kokkos/kokkos.git"
	if [ ${MY_PL} -gt 9999 ] ; then
		MYCY="${MY_PL%????}"
		MYCM="${MY_PL%??}" && MYCM="${MYCM#????}"
		MYCD="${MY_PL#??????}"
		EGIT_COMMIT_DATE="${MYCY}-${MYCM}-${MYCD}"
		MY_P="${MY_PN}-git-${EGIT_COMMIT_DATE}"
	else
		MY_P="${MY_PN}-git-${MY_PL}"
	fi
else
	MY_PV="${PV/_p/-patch}"
	MY_P="${MY_PN}-${MY_PV}"
	SRC_URI="http://github.com/kokkos/kokkos/archive/${MY_PV}.tar.gz"
fi

KOKKOS_PREFIX="${EPREFIX}/usr/lib/${MY_PN}/${P}"

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
	bash "${S}/generate_makefile.bash" --prefix="${KOKKOS_PREFIX}"
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
	dodoc ${DOCS[*]}

	# Install sources
	insinto "${EPREFIX}/usr/src/${CATEGORY}/${PN}"
	insopts ""
	doins -r "${S}" 

	# Fix up install paths before running make install
	pushd "${S}" > /dev/null
		mkdir -p "${D}/${KOKKOS_PREFIX}"
		sed -e 's:$(PREFIX):$(DESTDIR)/&:g' -i core/src/Makefile || die
	#	mkdir -p "${ED}/usr/share/${P}"
	#	sed -e 's:$(PREFIX)/\(lib\|include\):&/'"${P}"':g' -i core/src/Makefile core/src/Makefile.generate_build_files || die
	#	sed -e 's:$(PREFIX):$(DESTDIR)/&:g' \
	#		-e 's:.*cp.*KOKKOS.*MAKEFILE.*$(PREFIX).*:&/share/'"${P}"':' \
	#		-e 's:$(PREFIX)/bin:$(PREFIX)/share/'"${P}"':' \
	#		-i core/src/Makefile || die
	popd > /dev/null

	# Install libs, headers, and build files.
	pushd "${BUILD_DIR}" > /dev/null
		emake install PREFIX="${KOKKOS_PREFIX}" DESTDIR="${D%/}"
		sed -e 's:'"${S}"'/bin/nvcc_wrapper:'"${KOKKOS_EPREFIX}"'/bin/nvcc_wrapper:' -i "${D%/}/${KOKKOS_PREFIX}"/{Makefile.kokkos,kokkos_generated_settings.cmake} || die
	popd > /dev/null
}

