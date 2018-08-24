# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Provides for the dynamic modification of a user's environment via modulefiles."
HOMEPAGE="http://modules.sourceforge.net"
SRC_URI="https://github.com/cea-hpc/modules/releases/download/v${PV}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="${PV}"
KEYWORDS="*"
IUSE="+compat test +doc +examples"

CDEPEND=">=dev-lang/tcl-8.4 >=dev-tcltk/tclx-8.4"
DOCDEPEND="dev-python/sphinx"
TESTDEPEND="dev-util/dejagnu app-shells/tcsh"
COMPATDEPEND="sys-devel/gettext sys-devel/autoconf sys-devel/automake"
DEPEND="${CDEPEND}
	doc? ( ${DOCDEPEND} )
	compat? ( ${COMPATDEPEND} )
	test? ( ${TESTDEPEND} )
"
RDEPEND="${CDEPEND}"

src_configure() {
	econf \
	$(use_enable examples example-modulefiles) \
	$(use_enable compat compat-version) \
	--enable-versioning
}

src_compile() {
	default
	use doc &&	emake -C doc all
}

src_test() {
	emake test
}
