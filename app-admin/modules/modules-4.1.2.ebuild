# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Provides for the dynamic modification of a user's environment via modulefiles."
HOMEPAGE="http://modules.sourceforge.net"
SRC_URI="https://github.com/cea-hpc/modules/releases/download/v${PV}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="${PV}"
KEYWORDS="*"
IUSE="+compat test +doc"

CDEPEND=">=dev-lang/tcl-8.4"
DOCDEPEND="doc? ( dev-python/sphinx )"
TESTDEPEND="test? ( dev-util/dejagnu app-shells/tcsh )"
COMPATDEPEND="compat? ( sys-devel/gettext sys-devel/autoconf sys-devel/automake )"
DEPEND="${CDEPEND} ${DOCDEPEND} ${TESTDEPEND} ${COMPATDEPEND}"
RDEPEND="${CDEPEND}"

src_configure() {
	econf \
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
