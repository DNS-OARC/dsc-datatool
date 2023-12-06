from setuptools import find_packages, setup

setup(
    name='dsc_datatool',
    version='1.4.1',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    python_requires='>=3.5.1',
    install_requires=[
        'maxminddb>=1.2.0',
        'PyYAML>=3.11',
    ],
    extras_require={
        'dev': [
            'pytest>=4',
            'coverage',
            'watchdog',
        ],
    },
    entry_points={
        'console_scripts': [
            'dsc-datatool = dsc_datatool:main',
        ],
    },
    scripts=[
    ],
)
