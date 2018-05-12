# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )
#inherit eutils linux-info multilib-build unpacker
inherit versionator multilib-build unpacker

SUPER_PN='amdgpu-pro'
PKG_REV="${PV##*.}"
MY_PV=$(replace_version_separator 2 '-')
MY_P="${SUPER_PN}-${MY_PV}"
DESCRIPTION="New generation AMD closed-source drivers for Southern Islands (HD7730 Series) and newer chipsets"
HOMEPAGE="https://support.amd.com/en-us/download/workstation?os=Linux+x86_64"
SRC_URI="https://www2.ati.com/drivers/linux/ubuntu/${SUPER_PN}-${MY_PV}.tar.xz"

RESTRICT="strip fetch"

# The binary blobs include binaries for other open sourced packages, we don't want to include those parts, if they are
# selected, they should come from portage.
IUSE="+X +gles2 +opencl +opencl_legacy +opencl_pal +opengl +vdpau +vulkan +wayland +egl +gstreamer +xorg_drivers" 

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
	>=sys-devel/lld-6.0.1
	>=sys-devel/llvm-6.0.1
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

pkg_nofetch() {
	einfo "Please download"
	einfo "  -  ${MY_P}.tar.xz for ubuntu 18.04"
	einfo "from the beta tab on ${HOMEPAGE} and place them in ${DISTDIR}"
	einfo "Headless? Accept the licends, then try: 'wget  --referer \"${HOMEPAGE}\" \"${SRC_URI}\"' from your DISTFILES directory."
}

unpack_deb() {
	echo ">>> Unpacking ${1##*/} to ${PWD}"
	unpack $1
	unpacker ./data.tar*
	unpacker ./control.tar*
	rm -f debian-binary {control,data}.tar*
}

unpack_amd() {
	unpack_deb "${MY_P}/${1}.deb"
}

unpack_amd_all() {
	unpack_amd "${1}_all"
}
unpack_amd_64() {
	unpack_amd "${1}_amd64"
}
unpack_amd_32() {
	unpack_amd "${1}_i386"
}

unpack_amd_ml() {
	unpack_amd_64 "${1}"
	use abi_x86_32 && unpack_amd_32 "${1}"
}

unpack_amd_best() {
	if use abi_x86_64 ; then
		unpack_amd_64 "${1}"
	elif use abi_x86_32 ; then
		unpack_amd_32 "${1}"
	else
		ewarn "No available binary api!"
		die
	fi
}

xsrc_unpack() {
	default
	pushd "${WORKDIR}"
		for d in $(find -name *.deb ) ; do
			mkdir "${d%.deb}" || die
			pushd "${d%.deb}" > /dev/null
				unpack_deb "${WORKDIR}/${d}"
			popd
		done
	popd
}

_unpack_common() {
	unpack_amd_all "libgl1-amdgpu-pro-appprofiles_${MY_PV}"
	unpack_amd_ml "libdrm-amdgpu-amdgpu1_2.4.91-${PKG_REV}"
	unpack_amd_ml "libdrm-amdgpu-radeon1_2.4.91-${PKG_REV}"
	unpack_amd_best "libdrm-amdgpu-utils_2.4.91-${PKG_REV}"
}

_unpack_opengl() {
	# Install OpenGL
	unpack_amd_ml "libgl1-amdgpu-pro-glx_${MY_PV}"
	unpack_amd_best "libgl1-amdgpu-pro-ext_${MY_PV}"
	unpack_amd_ml "libgl1-amdgpu-pro-dri_${MY_PV}"
	
	# Install GBM
	unpack_amd_ml "libgbm1-amdgpu-pro_${MY_PV}"
	unpack_amd_ml "libgbm1-amdgpu-pro-dev_${MY_PV}"
	unpack_amd_all "libgbm1-amdgpu-pro-base_${MY_PV}"
}

_unpack_opencl() {

	# Install clinfo
	unpack_amd_best "clinfo-amdgpu-pro_${MY_PV}"
		
	# Install OpenCL components
	unpack_amd_ml "libopencl1-amdgpu-pro_${MY_PV}"
	unpack_amd_64 "opencl-amdgpu-pro-dev_${MY_PV}"
	if use opencl_legacy ; then unpack_amd_ml "opencl-orca-amdgpu-pro-icd_${MY_PV}" ; fi
	if use opencl_pal ; then
		unpack_amd_64 "opencl-amdgpu-pro-icd_${MY_PV}"
	fi

	# Install roct components
	unpack_amd_64 "roct-amdgpu-pro_1.0.8-${PKG_REV}"
	unpack_amd_64 "roct-amdgpu-pro-dev_1.0.8-${PKG_REV}"
}


_unpack_egl() {
	# Install EGL libs
	unpack_amd_ml "libegl1-amdgpu-pro_${MY_PV}"
}

_unpack_vulkan() {
	# Install Vulkan driver
	unpack_amd_ml "vulkan-amdgpu-pro_${MY_PV}"
}

_unpack_wayland() {
	# Install Wayland protocol drivers
	unpack_amd_all "wayland-protocols-amdgpu_1.13-${PKG_REV}"
	unpack_amd_ml "wsa-amdgpu_${MY_PV}"
}

_unpack_gles2() {
	# Install GLES2
	unpack_amd_ml "libgles2-amdgpu-pro_${MY_PV}"
}

_unpack_vdpau() {
	# Install VDPAU
	unpack_amd_ml "mesa-amdgpu-vdpau-drivers_18.0.0-${PKG_REV}"
}

_unpack_xorg_drivers() {
	# Install xorg drivers
	unpack_amd_best "xserver-xorg-amdgpu-video-amdgpu_1.4.0-${PKG_REV}"
}

_unpack_gstreamer_plugin() {
	# Install gstreamer OpenMAX plugin
	unpack_amd_ml "gst-omx-amdgpu_1.0.0.1-${PKG_REV}"
}

src_unpack() {
	default
	
	if use opengl ; then _unpack_opengl ; fi
	if use opencl ; then _unpack_opencl ; fi
	if use egl ; then _unpack_egl ; fi

	if use vulkan ; then _unpack_vulkan ; fi
	if use wayland ; then _unpack_wayland ; fi
	if use gles2 ; then _unpack_gles2 ; fi
	if use vdpau ; then _unpack_vdpau ; fi
	if use xorg_drivers ; then _unpack_xorg_drivers ; fi
	if use gstreamer ; then _unpack_gstreamer_plugin ; fi

}

src_prepare() {
	cat << EOF > "${T}/91-drm_pro-modeset.rules" || die
KERNEL=="controlD[0-9]*", SUBSYSTEM=="drm", MODE="0600"
EOF

	cat << EOF > "${T}/01-amdgpu.conf" || die
/usr/$(get_libdir)/gbm
/usr/lib32/gbm
EOF

	cat << EOF > "${T}/10-device.conf" || die
Section "Device"
	Identifier  "My graphics card"
	Driver      "amdgpu"
	BusID       "PCI:1:0:0"
	Option      "AccelMethod" "glamor"
	Option      "DRI" "3"
	Option		"TearFree" "on"
EndSection
EOF

	cat << EOF > "${T}/10-screen.conf" || die
Section "Screen"
		Identifier      "Screen0"
		DefaultDepth    24
		SubSection      "Display"
				Depth   24
		EndSubSection
EndSection
EOF

	cat << EOF > "${T}/10-monitor.conf" || die
Section "Monitor"
	Identifier   "My monitor"
	VendorName   "BrandName"
	ModelName    "ModelName"
	Option       "DPMS"   "true"
EndSection
EOF

	if use vulkan ; then
		cat << EOF > "${T}/amd_icd64.json" || die
{
   "file_format_version": "1.0.0",
	   "ICD": {
		   "library_path": "/usr/$(get_libdir)/vulkan/vendors/amdgpu/amdvlk64.so",
		   "abi_versions": "0.9.0"
	   }
}
EOF

		if use abi_x86_32 ; then
			cat << EOF > "${T}/amd_icd32.json" || die
{
   "file_format_version": "1.0.0",
	   "ICD": {
		   "library_path": "/usr/lib32/vulkan/vendors/amdgpu/amdvlk32.so",
		   "abi_versions": "0.9.0"
	   }
}
EOF
		fi
	fi

	eapply_user
}

src_install() {
	insinto /etc/udev/rules.d/
	doins "${T}/91-drm_pro-modeset.rules"
	insinto /etc/ld.so.conf.d
	doins "${T}/01-amdgpu.conf"
	insinto /etc/X11/xorg.conf.d
	doins "${T}/10-screen.conf"
	doins "${T}/10-monitor.conf"
	doins "${T}/10-device.conf"
	insinto /etc/amd/
	doins etc/amd/amdapfxx.blb
	
	into /usr/
	cd opt/amdgpu/bin/
	dobin amdgpu_test
	dobin kms-steal-crtc
	dobin kmstest
	dobin kms-universal-planes
	dobin modeprint
	dobin modetest
	dobin proptest
	dobin vbltest
	cd ../../..
	
	if use opencl ; then
		# Install clinfo
		into /usr/
		cd opt/amdgpu/bin/
		dobin clinfo
		cd ../../..
		
		# Install OpenCL components
		insinto /etc/OpenCL/vendors
		doins etc/OpenCL/vendors/amdocl64.icd
		doins etc/OpenCL/vendors/amdocl-rocr64.icd
		
		exeinto /usr/lib64/OpenCL/vendors/amdgpu
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libamdocl*
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libOpenCL.so.1
		dosym libOpenCL.so.1 /usr/lib64/OpenCL/vendors/amdgpu/libOpenCL.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libhsa-ext-finalize64.so.1.0.0
		dosym libhsa-ext-finalize64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-ext-finalize64.so.1.0
		dosym libhsa-ext-finalize64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-ext-finalize64.so.1
		dosym libhsa-ext-finalize64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-ext-finalize64.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libhsa-ext-image64.so.1.0.0
		dosym libhsa-ext-image64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-ext-image64.so.1.0
		dosym libhsa-ext-image64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-ext-image64.so.1
		dosym libhsa-ext-image64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-ext-image64.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libhsa-runtime-tools64.so.1.0.0
		dosym libhsa-runtime-tools64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-runtime-tools64.so.1.0
		dosym libhsa-runtime-tools64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-runtime-tools64.so.1
		dosym libhsa-runtime-tools64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-runtime-tools64.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libamdocl-rocr64.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libcltrace.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libhsa-runtime64.so.1.0.0
		dosym libhsa-runtime64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-runtime64.so.1.0
		dosym libhsa-runtime64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-runtime64.so.1
		dosym libhsa-runtime64.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsa-runtime64.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libhsakmt.so.1.0.0
		dosym libhsakmt.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsakmt.so.1.0
		dosym libhsakmt.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsakmt.so.1
		dosym libhsakmt.so.1.0.0 /usr/lib64/OpenCL/vendors/amdgpu/libhsakmt.so
		
		insinto /usr/include/hsa
		doins opt/amdgpu/include/hsa/hsa_ext_debugger.h
		doins opt/amdgpu/include/hsa/hsa_ext_profiler.h
		doins opt/amdgpu/include/hsa/amd_hsa_tools_interfaces.h
		doins opt/amdgpu/include/hsa/Brig.h
		doins opt/amdgpu/include/hsa/amd*
		doins opt/amdgpu/include/hsa/hsa*
		
		insinto /usr/include/libhsakmt
		doins opt/amdgpu/include/libhsakmt/hsakmt*
		
		insinto /usr/include/libhsakmt/linux
		doins opt/amdgpu/include/libhsakmt/linux/kfd_ioctl.h
		
		if use abi_x86_32 ; then
			# Install 32 bit OpenCL ICD
			insinto /etc/OpenCL/vendors
			doins etc/OpenCL/vendors/amdocl32.icd
			exeinto /usr/lib32/OpenCL/vendors/amdgpu
			doexe opt/amdgpu/lib/i386-linux-gnu/libamdocl*
			
			# Install 32 bit OpenCL library
			doexe opt/amdgpu/lib/i386-linux-gnu/libOpenCL.so.1
			dosym libOpenCL.so.1 /usr/lib32/OpenCL/vendors/amdgpu/libOpenCL.so
		fi
	fi
	
	if use vulkan ; then
		# Install Vulkan driver
		insinto /etc/vulkan/icd.d
		doins "${T}/amd_icd64.json"
		exeinto /usr/lib64/vulkan/vendors/amdgpu
		doexe opt/amdgpu/lib/x86_64-linux-gnu/amdvlk64.so

		if use abi_x86_32 ; then
			# Install Vulkan driver
			insinto /etc/vulkan/icd.d
			doins "${T}/amd_icd32.json"
			exeinto /usr/lib32/vulkan/vendors/amdgpu
			doexe opt/amdgpu/lib/i386-linux-gnu/amdvlk32.so
		fi
	fi
	
	if use opengl ; then
		# Install OpenGL
		exeinto /usr/lib64/opengl/amdgpu/lib
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0
		dosym libdrm_amdgpu.so.1.0.0 /usr/lib64/opengl/amdgpu/lib/libdrm_amdgpu.so.1
		dosym libdrm_amdgpu.so.1.0.0 /usr/lib64/opengl/amdgpu/lib/libdrm_amdgpu.so
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libGL.so.1.2
		dosym libGL.so.1.2 /usr/lib64/opengl/amdgpu/lib/libGL.so.1
		dosym libGL.so.1.2 /usr/lib64/opengl/amdgpu/lib/libGL.so
		exeinto /usr/lib64/opengl/radeon/lib
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1
		dosym libdrm_radeon.so.1.0.1 /usr/lib64/opengl/radeon/lib/libdrm_radeon.so.1
		dosym libdrm_radeon.so.1.0.1 /usr/lib64/opengl/radeon/lib/libdrm_radeon.so
		insinto /etc/amd/
		doins etc/amd/amdrc
		exeinto /usr/lib64/opengl/amdgpu/extensions
		doexe opt/amdgpu/lib/xorg/modules/extensions/libglx.so
		exeinto /usr/lib64/opengl/amdgpu/dri
		doexe usr/lib/x86_64-linux-gnu/dri/amdgpu_dri.so
		dosym ../opengl/amdgpu/dri/amdgpu_dri.so /usr/lib64/dri/amdgpu_dri.so
		dosym ../../opengl/amdgpu/dri/amdgpu_dri.so /usr/lib64/x86_64-linux-gnu/dri/amdgpu_dri.so
		
		# Install GBM
		exeinto /usr/lib64/opengl/amdgpu/lib
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libgbm.so.1.0.0
		dosym libgbm.so.1.0.0 /usr/lib64/opengl/amdgpu/lib/libgbm.so.1
		dosym libgbm.so.1.0.0 /usr/lib64/opengl/amdgpu/lib/libgbm.so
		exeinto /usr/lib64/opengl/amdgpu/gbm
		doexe opt/amdgpu/lib/x86_64-linux-gnu/gbm/gbm_amdgpu.so
		dosym gbm_amdgpu.so /usr/lib64/opengl/amdgpu/gbm/libdummy.so
		dosym opengl/amdgpu/gbm /usr/lib64/gbm
		insinto /etc/gbm/
		doins etc/gbm/gbm.conf
		
		if use abi_x86_32 ; then
			# Install 32 bit OpenGL
			exeinto /usr/lib32/opengl/amdgpu/lib
			doexe opt/amdgpu/lib/i386-linux-gnu/libdrm_amdgpu.so.1.0.0
			dosym libdrm_amdgpu.so.1.0.0 /usr/lib32/opengl/amdgpu/lib/libdrm_amdgpu.so.1
			dosym libdrm_amdgpu.so.1.0.0 /usr/lib32/opengl/amdgpu/lib/libdrm_amdgpu.so
			doexe opt/amdgpu/lib/i386-linux-gnu/libGL.so.1.2
			dosym libGL.so.1.2 /usr/lib32/opengl/amdgpu/lib/libGL.so.1
			dosym libGL.so.1.2 /usr/lib32/opengl/amdgpu/lib/libGL.so
			exeinto /usr/lib32/opengl/radeon/lib
			doexe opt/amdgpu/lib/i386-linux-gnu/libdrm_radeon.so.1.0.1
			dosym libdrm_radeon.so.1.0.1 /usr/lib32/opengl/radeon/lib/libdrm_radeon.so.1
			dosym libdrm_radeon.so.1.0.1 /usr/lib32/opengl/radeon/lib/libdrm_radeon.so
			exeinto /usr/lib32/opengl/amdgpu/dri
			doexe usr/lib/i386-linux-gnu/dri/amdgpu_dri.so
			dosym ../opengl/amdgpu/dri/amdgpu_dri.so /usr/lib32/dri/amdgpu_dri.so
			dosym ../../opengl/amdgpu/dri/amdgpu_dri.so /usr/lib64/i386-linux-gnu/dri/amdgpu_dri.so
			
			# Install GBM
			exeinto /usr/lib32/opengl/amdgpu/lib
			doexe opt/amdgpu/lib/i386-linux-gnu/libgbm.so.1.0.0
			dosym libgbm.so.1.0.0 /usr/lib32/opengl/amdgpu/lib/libgbm.so.1
			dosym libgbm.so.1.0.0 /usr/lib32/opengl/amdgpu/lib/libgbm.so
			exeinto /usr/lib32/opengl/amdgpu/gbm
			doexe opt/amdgpu/lib/i386-linux-gnu/gbm/gbm_amdgpu.so
			dosym gbm_amdgpu.so /usr/lib32/opengl/amdgpu/gbm/libdummy.so
			dosym opengl/amdgpu/gbm /usr/lib32/gbm
		fi
	fi
	
	if use gles2 ; then
		# Install GLES2
		exeinto /usr/lib64/opengl/amdgpu/lib
		doexe opt/amdgpu/lib/x86_64-linux-gnu/libGLESv2.so.2
		dosym libGLESv2.so.2 /usr/lib64/opengl/amdgpu/lib/libGLESv2.so

		if use abi_x86_32 ; then
			exeinto /usr/lib32/opengl/amdgpu/lib
			doexe opt/amdgpu/lib/i386-linux-gnu/libGLESv2.so.2
			dosym libGLESv2.so.2 /usr/lib32/opengl/amdgpu/lib/libGLESv2.so
		fi
	fi
	
	# Install EGL libs
	exeinto /usr/lib64/opengl/amdgpu/lib
	doexe opt/amdgpu/lib/x86_64-linux-gnu/libEGL.so.1
	dosym libEGL.so.1 /usr/lib64/opengl/amdgpu/lib/libEGL.so

	if use abi_x86_32 ; then
		exeinto /usr/lib32/opengl/amdgpu/lib
		doexe opt/amdgpu/lib/i386-linux-gnu/libEGL.so.1
		dosym libEGL.so.1 /usr/lib32/opengl/amdgpu/lib/libEGL.so
	fi
	
	if use vdpau ; then
		# Install VDPAU
		exeinto /usr/lib64/opengl/amdgpu/vdpau/
		doexe opt/amdgpu/lib/x86_64-linux-gnu/vdpau/libvdpau_amdgpu.so.1.0.0
		dosym ../opengl/amdgpu/vdpau/libvdpau_amdgpu.so.1.0.0 /usr/lib64/vdpau/libvdpau_amdgpu.so.1.0.0
		dosym libvdpau_amdgpu.so.1.0.0 /usr/lib64/vdpau/libvdpau_amdgpu.so.1.0
		dosym libvdpau_amdgpu.so.1.0.0 /usr/lib64/vdpau/libvdpau_amdgpu.so.1
		dosym libvdpau_amdgpu.so.1.0.0 /usr/lib64/vdpau/libvdpau_amdgpu.so
		exeinto /usr/lib64/opengl/amdgpu/dri/
		doexe opt/amdgpu/lib/x86_64-linux-gnu/dri/radeonsi_drv_video.so
		if use abi_x86_32 ; then
			exeinto /usr/lib32/opengl/amdgpu/vdpau/
			doexe opt/amdgpu/lib/i386-linux-gnu/vdpau/libvdpau_amdgpu.so.1.0.0
			dosym ../opengl/amdgpu/vdpau/libvdpau_amdgpu.so.1.0.0 /usr/lib32/vdpau/libvdpau_amdgpu.so.1.0.0
			dosym libvdpau_amdgpu.so.1.0.0 /usr/lib32/vdpau/libvdpau_amdgpu.so.1.0
			dosym libvdpau_amdgpu.so.1.0.0 /usr/lib32/vdpau/libvdpau_amdgpu.so.1
			dosym libvdpau_amdgpu.so.1.0.0 /usr/lib32/vdpau/libvdpau_amdgpu.so
			exeinto /usr/lib32/opengl/amdgpu/dri/
			doexe opt/amdgpu/lib/i386-linux-gnu/dri/radeonsi_drv_video.so
		fi
	fi
	
	# Install xorg drivers
	exeinto /usr/lib64/opengl/amdgpu/modules/drivers
	doexe opt/amdgpu/lib/xorg/modules/drivers/amdgpu_drv.so
	
	# Install gstreamer OpenMAX plugin
	insinto /etc/xdg/
	doins etc/xdg/gstomx.conf
	exeinto /usr/lib64/gstreamer-1.0/
	doexe opt/amdgpu/lib/x86_64-linux-gnu/gstreamer-1.0/libgstomx.so
	if use abi_x86_32 ; then
		exeinto /usr/lib32/gstreamer-1.0/
		doexe opt/amdgpu/lib/i386-linux-gnu/gstreamer-1.0/libgstomx.so
	fi
	
	# Link for hardcoded path
	dosym /usr/share/libdrm/amdgpu.ids /opt/amdgpu/share/libdrm/amdgpu.ids
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
