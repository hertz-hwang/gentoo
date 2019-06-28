# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{5,6,7} )

inherit autotools linux-info python-r1 systemd

DESCRIPTION="Linux kernel (3.13+) firewall, NAT and packet mangling tools"
HOMEPAGE="https://netfilter.org/projects/nftables/"
#SRC_URI="https://git.netfilter.org/nftables/snapshot/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://netfilter.org/projects/nftables/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ia64 ~x86"
IUSE="debug +gmp json +modern_kernel python +readline static-libs"

RDEPEND="${PYTHON_DEPS}
	>=net-libs/libmnl-1.0.3:0=
	gmp? ( dev-libs/gmp:0= )
	json? ( dev-libs/jansson )
	readline? ( sys-libs/readline:0= )
	>=net-libs/libnftnl-1.1.3:0="

DEPEND="${RDEPEND}"

BDEPEND="
	>=app-text/docbook2X-0.8.8-r4
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

#S="${WORKDIR}/v${PV}"

PATCHES=(
	"${FILESDIR}"/${P}-python_build.patch
	"${FILESDIR}"/${P}-avoid_dive_into_py_subdir.patch
)

python_make() {
	emake \
		-C py \
		abs_builddir="${S}" \
		DESTDIR="${D}" \
		PYTHON_BIN="${PYTHON}" \
		${@}
}

pkg_setup() {
	if kernel_is ge 3 13; then
		if use modern_kernel && kernel_is lt 3 18; then
			eerror "The modern_kernel USE flag requires kernel version 3.18 or newer to work properly."
		fi
		CONFIG_CHECK="~NF_TABLES"
		linux-info_pkg_setup
	else
		eerror "This package requires kernel version 3.13 or newer to work properly."
	fi
}

src_prepare() {
	default

	# fix installation path for doc stuff
	sed '/^pkgsysconfdir/s@${sysconfdir}.*$@${docdir}@' \
		-i files/nftables/Makefile.am || die
	sed '/^pkgsysconfdir/s@${sysconfdir}.*$@${docdir}/osf@' \
		-i files/osf/Makefile.am || die

	eautoreconf
}

src_configure() {
	local myeconfargs=(
		# We handle python separately
		--disable-python
		--sbindir="${EPREFIX}"/sbin
		$(use_enable debug)
		$(use_with !gmp mini_gmp)
		$(use_with json)
		$(use_with readline cli)
		$(use_enable static-libs static)
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	default

	if use python ; then
		python_foreach_impl python_make
	fi
}

src_install() {
	default

	local mksuffix="$(usex modern_kernel '-mk' '')"

	exeinto /usr/libexec/${PN}
	newexe "${FILESDIR}"/libexec/${PN}${mksuffix}.sh ${PN}.sh
	newconfd "${FILESDIR}"/${PN}${mksuffix}.confd ${PN}
	newinitd "${FILESDIR}"/${PN}${mksuffix}.init ${PN}
	keepdir /var/lib/nftables

	systemd_dounit "${FILESDIR}"/systemd/${PN}-restore.service

	if use python ; then
		python_foreach_impl python_make install
	fi

	find "${ED}" -type f -name "*.la" -delete || die
}

pkg_postinst() {
	local save_file
	save_file="${EROOT}/var/lib/nftables/rules-save"

	# In order for the nftables-restore systemd service to start
	# the save_file must exist.
	if [[ ! -f ${save_file} ]]; then
		touch ${save_file}
	fi

	elog "If you wish to enable the firewall rules on boot (on systemd) you"
	elog "will need to enable the nftables-restore service."
	elog "    'systemd_enable_service basic.target ${PN}-restore.service'"
	elog
	elog "If you are creating firewall rules before the next system restart "
	elog "the nftables-restore service must be manually started in order to "
	elog "save those rules on shutdown."
}
