# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="High performance C/C++ library for compressed numerical arrays by LLNL."
HOMEPAGE="https://computation.llnl.gov/projects/floating-point-compression"
SRC_URI="https://github.com/LLNL/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

inherit cmake-utils

LICENSE="BSD"
SLOT="8/8.4.0"
KEYWORDS="~amd64 ~x86"
IUSE="openmp examples +tools test"

DEPEND=""
RDEPEND="${DEPEND}"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_SKIP_INSTALL_RPATH=YES
		-DCMAKE_SKIP_RPATH=YES
		-DZFP_WITH_OPENMP=$(usex openmp ON OFF)
		-DBUILD_UTILITIES=$(usex tools ON OFF)
		-DBUILD_EXAMPLES=$(usex examples ON OFF)
		-DBUILD_TESTING=$(usex test ON OFF)
	)
	if use test ; then
		mycmakeargs=(
			-DZFP_BUILD_TESTING_SMALL=ON
			-DZFP_BUILD_TESTING_MEDIUM=ON
			-DZFP_BUILD_TESTING_LARGE=ON
		)
	fi
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	pushd "${BUILD_DIR}/bin"
		use tools && exeinto "/usr/bin" &&  doexe zfp
		if use examples ; then
			dodir "/usr/share/doc/${P}/examples/bin"
			pushd "${S}/examples" 
				insinto "/usr/share/doc/${P}/examples"
				doins *
			popd
			exeinto "/usr/share/doc/${P}/examples/bin"
			doexe $(ls -1 | grep -vFx zfp )
		fi
	popd
}
