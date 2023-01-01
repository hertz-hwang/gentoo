# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} pypy3 )

inherit distutils-r1

DESCRIPTION="Install packages and run Python with them"
HOMEPAGE="
	https://github.com/jaraco/pip-run/
	https://pypi.org/project/pip-run/
"
SRC_URI="
	https://github.com/jaraco/pip-run/archive/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~x86"

RDEPEND="
	dev-python/autocommand[${PYTHON_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/importlib_resources[${PYTHON_USEDEP}]
	' 3.8)
	dev-python/jaraco-context[${PYTHON_USEDEP}]
	dev-python/jaraco-functools[${PYTHON_USEDEP}]
	dev-python/jaraco-text[${PYTHON_USEDEP}]
	>=dev-python/more-itertools-8.3[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	dev-python/path[${PYTHON_USEDEP}]
	dev-python/pip[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/jaraco-path[${PYTHON_USEDEP}]
		>=dev-python/jaraco-test-5.3[${PYTHON_USEDEP}]
		dev-python/pygments[${PYTHON_USEDEP}]
		$(python_gen_cond_dep '
			dev-python/nbformat[${PYTHON_USEDEP}]
		' 'python*')
	)
"

distutils_enable_tests pytest

export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}

python_test() {
	local EPYTEST_IGNORE=()

	if ! has_version "dev-python/nbformat[${PYTHON_USEDEP}]"; then
		EPYTEST_IGNORE+=(
			tests/test_scripts.py
		)
	fi

	epytest -m "not network"
}
