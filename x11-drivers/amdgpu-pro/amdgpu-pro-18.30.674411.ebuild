# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )
#inherit eutils linux-info multilib-build unpacker
inherit versionator multilib-build deb

SUPER_PN='amdgpu-pro'
PKG_REV="${PV##*.}"
DIST_REV="ubuntu-18.04"
MY_PV=$(replace_version_separator 2 '-')
MY_P="${SUPER_PN}-${MY_PV}-${DIST_REV}"
DESCRIPTION="New generation AMD closed-source drivers for Southern Islands (HD7730 Series) and newer chipsets"
HOMEPAGE="https://www.amd.com/en/support/kb/release-notes/rn-pro-lin-18-q4"
SRC_URI="https://drivers.amd.com/drivers/linux/${MY_P}.tar.xz"

RESTRICT="strip fetch"

# The binary blobs include binaries for other open sourced packages, we don't want to include those parts, if they are
# selected, they should come from portage.
IUSE="+opencl +opencl_legacy +opencl_pal +opengl +vulkan headless" 

REQUIRED_USE="
	opencl? ( || ( opencl_legacy opencl_pal ) )
	headless? ( opencl )
	!headless? ( || ( opengl vulkan ) )
"

LICENSE="AMD-GPU-PRO-EULA AMD GPL-2 QPL-1.0"
KEYWORDS="~amd64"
SLOT="1"

RDEPEND="
	>=app-eselect/eselect-opengl-1.0.7
	app-eselect/eselect-opencl
	dev-libs/openssl[${MULTILIB_USEDEP}]
	dev-util/cunit
	>=media-libs/gst-plugins-base-1.6.0[${MULTILIB_USEDEP}]
	>=media-libs/gstreamer-1.6.0[${MULTILIB_USEDEP}]
	media-libs/libomxil-bellagio
	!vulkan? ( >=media-libs/mesa-18.0.0[openmax] )
	vulkan? ( >=media-libs/mesa-18.0.0[openmax,-vulkan] media-libs/vulkan-loader )
	opencl? ( >=sys-devel/gcc-5.2.0 )
	>=sys-devel/lld-6
	>=sys-devel/llvm-6
	>=sys-libs/ncurses-5.0.0:5[${MULTILIB_USEDEP},tinfo]
	=x11-base/xorg-drivers-1.19
	=x11-base/xorg-server-1.19*[glamor]
	>=x11-libs/libdrm-2.4.91
	x11-libs/libX11[${MULTILIB_USEDEP}]
	x11-libs/libXext[${MULTILIB_USEDEP}]
	x11-libs/libXinerama[${MULTILIB_USEDEP}]
	x11-libs/libXrandr[${MULTILIB_USEDEP}]
	x11-libs/libXrender[${MULTILIB_USEDEP}]
	x11-proto/inputproto
	x11-proto/xf86miscproto
	x11-proto/xf86vidmodeproto
	x11-proto/xineramaproto
"
DEPEND="
	>=sys-kernel/linux-firmware-20161205
"

S="${WORKDIR}"


# Variables from installer, with AMDGPU_ prepended, PACKAGES normalized to plural, and defined as arrays.
AMDGPU_BASE_PACKAGES=(amdgpu-core)
AMDGPU_META_PACKAGES=(amdgpu)
AMDGPU_OPENGL_META_PACKAGES=(amdgpu-pro)
AMDGPU_OPENCL_LEGACY_META_PACKAGES=(clinfo-amdgpu-pro opencl-orca-amdgpu-pro-icd)
AMDGPU_OPENCL_PAL_META_PACKAGES=(clinfo-amdgpu-pro opencl-amdgpu-pro-icd)
AMDGPU_VULKAN_META_PACKAGES=(vulkan-amdgpu-pro)
AMDGPU_LIB32_META_PACKAGES=(amdgpu-lib32)
AMDGPU_LIB32_OPENGL_META_PACKAGES=(amdgpu-pro-lib32)
AMDGPU_LIB32_VULKAN_META_PACKAGES=(vulkan-amdgpu-pro:i386)
AMDGPU_PX_PACKAGES=(xserver-xorg-video-modesetting-amdgpu-pro)



pkg_nofetch() {
	einfo "Please download"
	einfo "  -  ${MY_P}.tar.xz for ubuntu 18.04"
	einfo "from the beta tab on ${HOMEPAGE} and place them in ${DISTDIR}"
	einfo "Headless? Accept the license, then try: 'wget  --referer \"${HOMEPAGE}\" \"${SRC_URI}\"' from your DISTFILES directory."
}

src_unpack() {
	default

	# Build list of packages to install based on use flags
	local my_pkgs=()
	if use opencl ; then
		if use opencl_legacy ; then my_pkgs+=( ${AMDGPU_OPENCL_LEGACY_META_PACKAGES[*]} ) ; fi
		if use opencl_pal ; then my_pkgs+=( ${AMDGPU_OPENCL_PAL_META_PACKAGES[*]} ) ; fi
	fi
	if ! use headless ; then
		if use opengl ; then
			my_pkgs+=( ${AMDGPU_OPENGL_META_PACKAGES[*]} ${AMDGPU_LIB32_OPENGL_META_PACKAGES[*]} )
		fi
		if use vulkan ; then
			my_pkgs+=( ${AMDGPU_VULKAN_META_PACKAGES[*]} ${AMDGPU_LIB32_VULKAN_META_PACKAGES[*]} )
		fi
	fi

	mkdir myroot
	pushd "${WORKDIR}/myroot"
		deb-extract_arch_debs_in_dir_with_local_deps amd64 "${WORKDIR}/${MY_P}" ${my_pkgs[*]}
		#for d in $(find -name *.deb ) ; do
		#	mkdir "${d%.deb}" || die
		#	pushd "${d%.deb}" > /dev/null
		#		unpack_deb "${WORKDIR}/${d}"
		#	popd
		#done
	popd
}

src_install() {
	pushd "${WORKDIR}/myroot" > /dev/null
		# Copy over all of /opt and /etc, but only /usr/share
		cp -r opt etc lib "${ED}"
		mkdir -p "${ED}/usr"
		cp -r usr/share "${ED}/usr"

		# Link dri drivers
		mkdir -p "${ED}/usr/lib64/dri"
		( set +f; for f in opt/amdgpu/lib/x86_64-linux-gnu/dri/*_dri.so; do ln -sb "${EPREFIX}/${f}" "${ED}/usr/lib64/dri/${f##*/}" ; done )
		( set +f; for f in opt/amdgpu/lib/x86_64-linux-gnu/dri/*_drv_video.so; do ln -sb "${EPREFIX}/${f}" "${ED}/usr/lib64/dri/${f##*/}" ; done )
		if use abi_x86_32; then
		mkdir -p "${ED}/usr/lib32/dri"
			( set +f; for f in opt/amdgpu/lib/i386-linux-gnu/dri/*_dri.so; do ln -sb "${EPREFIX}/${f}" "${ED}/usr/lib32/dri/${f##*/}" ; done )
			( set +f; for f in opt/amdgpu/lib/i386-linux-gnu/dri/*_drv_video.so; do ln -sb "${EPREFIX}/${f}" "${ED}/usr/lib32/dri/${f##*/}" ; done )
		fi

	popd
}

pkg_prerm() {
	einfo "pkg_prerm"
	if use opengl ; then
		"${ROOT}"/usr/bin/eselect opengl set --use-old xorg-x11
	fi

	if use opencl ; then
		"${ROOT}"/usr/bin/eselect opencl set --use-old mesa
	fi
}

pkg_postinst() {
	einfo "pkg_postinst"
	if use opengl ; then
		"${ROOT}"/usr/bin/eselect opengl set --use-old amdgpu
	fi

	if use opencl ; then
		"${ROOT}"/usr/bin/eselect opencl set --use-old amdgpu
	fi
}
