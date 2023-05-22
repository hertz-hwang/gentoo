# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..11} )

inherit distutils-r1 pypi

DESCRIPTION="Fast JSON schema validator for Python"
HOMEPAGE="
	https://github.com/horejsek/python-fastjsonschema/
	https://pypi.org/project/fastjsonschema/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"

distutils_enable_tests pytest

EPYTEST_IGNORE=(
	tests/benchmarks
)

src_prepare() {
	distutils-r1_src_prepare
	# stray directory?
	# https://github.com/horejsek/python-fastjsonschema/issues/173
	rm -r tests/examples/lengths || die
}
